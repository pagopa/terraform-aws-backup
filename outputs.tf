output "backup_vault_id" {
  value       = aws_backup_vault.vault.id
  description = "Backup Vault ID"
}

output "backup_vault_arn" {
  value       = aws_backup_vault.vault.arn
  description = "Backup Vault ARN"
}

output "backup_plan_arn" {
  value       = join("", aws_backup_plan.backup_plan.*.arn)
  description = "Backup Plan ARN"
}

output "backup_plan_version" {
  value       = join("", aws_backup_plan.backup_plan.*.version)
  description = "Unique, randomly generated, Unicode, UTF-8 encoded string that serves as the version ID of the backup plan"
}