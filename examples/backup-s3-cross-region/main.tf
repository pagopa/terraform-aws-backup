resource "random_integer" "bucket_suffix" {
  min = 1
  max = 9999
}
resource "aws_s3_bucket" "example" {
  bucket = format("bucket2backup-%04s", random_integer.bucket_suffix.result)

  tags = {
    Name               = "S3 Remote Terraform State Store"
    DataClassification = "PII customer data"
  }
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.example.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.example.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.example]
}

# IMPORTANT: versioning must be enabled to backup a S3 bucket
resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.example.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# Backup role.
resource "aws_iam_role" "example" {
  name = "example-backup-role" # Replace with your desired role name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}


# Required policy to backup the S3 objects.
resource "aws_iam_policy" "example" {
  name        = "example-backup-policy" # Replace with your desired policy name
  description = "Policy for AWS Backup to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:Get*",
          "s3:PutBucketNotification",
          "s3:PutObject",
          "s3:ListBucket*"
        ],
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.example.arn}/*",
          "${aws_s3_bucket.example.arn}"
        ]
      },
      {
        Action = [
          "events:DescribeRule",
          "events:EnableRule",
          "events:PutRule",
          "events:DeleteRule",
          "events:PutTargets",
          "events:RemoveTargets",
          "events:ListTargetsByRule",
          "events:DisableRule"
        ],
        Effect   = "Allow"
        Resource = "arn:aws:events:*:*:rule/AwsBackupManagedRule*"
      },
      {
        Action   = "tag:GetResources"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          StringLike = {
            "kms:ViaService" : "s3.*.amazonaws.com"
          }
        }
      },
      {
        Action = [
          "cloudwatch:GetMetricData",
          "events:ListRules"
        ],
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "example" {
  name   = "example-backup-role-policy" # Replace with your desired role policy name
  role   = aws_iam_role.example.name
  policy = aws_iam_policy.example.policy
}



# Create vault in eu-west-1
module "aws_backup_copy" {
  source       = "../../"
  name         = "backup-copy"
  iam_role_arn = aws_iam_role.example.arn

  providers = {
    aws = aws.eu-west-1
  }

  selection_tag = null

  backup_rule = []
}


module "aws_backup" {
  source       = "../../"
  name         = "s3-backup"
  iam_role_arn = aws_iam_role.example.arn

  selection_tag = {
    key   = "DataClassification"
    value = "PII customer data"
  }

  enable_vault_lock_governance = false

  backup_rule = [{
    rule_name         = "backup_evary_hour_rule"
    schedule          = "cron(5 */1 * * ? *)"
    start_window      = 60
    completion_window = 140

    lifecycle = {
      delete_after = 14
    }

    copy_action = {
      destination_vault_arn = module.aws_backup_copy.backup_vault_arn

      lifecycle = {
        cold_storage_after = 30
        delete_after       = 30
      }
    }
  }]
}

