data "aws_caller_identity" "current" {}


data "aws_iam_policy_document" "kms_key_policy" {
  #checkov:skip=CKV_AWS_111: Not applicable since it's a resource policy
  #checkov:skip=CKV_AWS_109: Not applicable since it's a resource policy
  #checkov:skip=CKV_AWS_356: Not applicable since it's a resource policy
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    #todo: define who can administer the key
    #proposal: admin backup.

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
    ]
    resources = ["*"]
  }

}


resource "aws_kms_key" "kms_key" {
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_key_policy.json
}

resource "random_id" "salt" {
  byte_length = 4
}

resource "aws_backup_vault" "vault" {
  name        = "${var.name}-vault-${random_id.salt.hex}"
  kms_key_arn = aws_kms_key.kms_key.arn
  tags        = var.tags
}

resource "aws_backup_vault_lock_configuration" "vault_lock" {
  count             = var.enable_vault_lock_governance ? 1 : 0
  backup_vault_name = aws_backup_vault.vault.name
}

resource "aws_backup_plan" "backup_plan" {

  count = length(var.backup_rule) > 0 ? 1 : 0

  name = "${var.name}-plan-${random_id.salt.hex}"

  dynamic "rule" {
    for_each = var.backup_rule
    content {
      rule_name                = rule.value.rule_name
      target_vault_name        = aws_backup_vault.vault.name
      schedule                 = try(rule.value.schedule, null)
      enable_continuous_backup = try(rule.value.enable_continuous_backup, null)
      start_window             = try(rule.value.start_window, null)
      completion_window        = try(rule.value.completion_window, null)
      dynamic "lifecycle" {
        for_each = try(rule.value.lifecycle, null) != null ? ["enabled"] : []
        content {
          cold_storage_after = try(rule.value.lifecycle.cold_storage_after, null)
          delete_after       = try(rule.value.lifecycle.delete_after, null)
        }
      }
      recovery_point_tags = try(rule.value.recovery_point_tags, null)
      dynamic "copy_action" {
        for_each = try(rule.value.copy_action, null) != null ? ["enabled"] : []
        content {
          destination_vault_arn = rule.value.copy_action.destination_vault_arn
          dynamic "lifecycle" {
            for_each = try(rule.value.copy_action.lifecycle, null) != null ? ["enabled"] : []

            content {
              cold_storage_after = try(rule.value.copy_action.lifecycle.cold_storage_after, null)
              delete_after       = try(rule.value.copy_action.lifecylce.delete_after, null)
            }
          }
        }
      }
    }
  }
  tags = var.tags
}
resource "aws_backup_selection" "backup_selection" {
  count        = var.selection_tag == null ? 0 : 1
  name         = "${var.name}-backup-selection-${random_id.salt.hex}"
  plan_id      = aws_backup_plan.backup_plan[0].id
  iam_role_arn = var.iam_role_arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.selection_tag["key"]
    value = var.selection_tag["value"]
  }
}


resource "aws_sns_topic" "backup_vault_events" {
  count = var.create_sns_topic ? 1 : 0
  name  = "backup-vault-events"
}

data "aws_iam_policy_document" "sns_publish" {
  count     = var.create_sns_topic ? 1 : 0
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Publish",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.backup_vault_events[0].arn,
    ]

    sid = "__default_statement_ID"
  }
}

resource "aws_sns_topic_policy" "sns_publish" {
  count  = var.create_sns_topic ? 1 : 0
  arn    = aws_sns_topic.backup_vault_events[0].arn
  policy = data.aws_iam_policy_document.sns_publish[0].json
}


resource "aws_backup_vault_notifications" "vault_notifications" {
  count               = var.create_sns_topic ? 1 : 0
  backup_vault_name   = aws_backup_vault.vault.name
  sns_topic_arn       = aws_sns_topic.backup_vault_events[0].arn
  backup_vault_events = var.backup_vault_events
}