locals {
  tag_key   = "DataClassification"
  tag_value = "PII customer data"
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
  name        = "dynamodb-backup-policy" # Replace with your desired policy name
  description = "Policy for AWS Backup to backup Dynamodb table."

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "dynamodb:DescribeTable",
            "dynamodb:CreateBackup"
          ],
          Resource = "arn:aws:dynamodb:*:*:table/*"
        },
        {
          Effect = "Allow",
          Action = [
            "dynamodb:DescribeBackup",
            "dynamodb:DeleteBackup"
          ],
          Resource = "arn:aws:dynamodb:*:*:table/*/backup/*"
        },
        {
          Effect = "Allow",
          Action = [
            "backup:DescribeBackupVault",
            "backup:CopyIntoBackupVault"
          ],
          Resource = "arn:aws:backup:*:*:backup-vault:*"
        },
        {
          Effect   = "Allow",
          Action   = "kms:DescribeKey",
          Resource = "*"
        },
        {
          Effect   = "Allow",
          Action   = "kms:CreateGrant",
          Resource = "*",
          "Condition" : {
            "Bool" : {
              "kms:GrantIsForAWSResource" : "true"
            }
          }
        },
        {
          Effect = "Allow",
          Action = [
            "tag:GetResources"
          ],
          Resource = "*"
        },
        {
          "Sid" : "DynamodbBackupPermissions",
          Effect = "Allow",
          Action = [
            "dynamodb:StartAwsBackupJob",
            "dynamodb:ListTagsOfResource"
          ],
          Resource = "arn:aws:dynamodb:*:*:table/*"
        }
      ]
  })

}

resource "aws_dynamodb_table" "example" {
  name           = "example-table"
  read_capacity  = 10
  write_capacity = 10
  hash_key       = "exampleHashKey"

  attribute {
    name = "exampleHashKey"
    type = "S"
  }

  tags = {
    CreatedBy          = "Terraform"
    DataClassification = "PII customer data"
  }

}

resource "aws_dynamodb_table_item" "example" {
  table_name = aws_dynamodb_table.example.name
  hash_key   = aws_dynamodb_table.example.hash_key

  item = <<ITEM
{
  "exampleHashKey": {"S": "something"},
  "one": {"N": "11111"},
  "two": {"N": "22222"},
  "three": {"N": "33333"},
  "four": {"N": "44444"}
}
ITEM

}

resource "aws_iam_role_policy" "example" {
  name   = "example-backup-role-policy" # Replace with your desired role policy name
  role   = aws_iam_role.example.name
  policy = aws_iam_policy.example.policy
}


module "aws_backup" {
  source       = "../../"
  name         = "dynamodb-backup"
  iam_role_arn = aws_iam_role.example.arn

  selection_tag = {
    key   = "DataClassification"
    value = "PII customer data"
  }

  enable_vault_lock_governance = true

  backup_rule = [{
    rule_name = "backup_on_wednesday_at_14"
    # At 12:00 AM UTC and 02:00 PM UTC, only on Wednesday
    schedule          = "cron(0 0,14 ? * WED *)"
    start_window      = 60
    completion_window = 140
    lifecycle = {
      #DeleteAfterDays cannot be less than 90 days apart from MoveToColdStorageAfterDays
      delete_after = 120
      # Move the backup to a cold storage after 30 days
      cold_storage_after = 30

    }
    }
  ]
}
