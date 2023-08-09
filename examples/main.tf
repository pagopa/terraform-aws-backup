module "aws_backup" {
  source       = "../"
  name         = "my-backup"
  iam_role_arn = "arn:aws:iam::111122223333:role/AWSBackupCustomRole"
  selection_tag = {
    key   = "foo"
    value = "bar"
  }
  enable_vault_lock_governance = false
  backup_rule = [{
    rule_name         = "backup_daily_rule"
    schedule          = "cron(0 20 * * ? *)"
    start_window      = 60
    completion_window = 140
    lifecycle = {
      delete_after = 14
    }
    },
    {
      rule_name = "backup_default_rule"

    }
  ]

}
