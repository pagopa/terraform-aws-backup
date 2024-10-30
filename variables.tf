variable "name" {
  description = "The name of the supporting resources"
  type        = string

}

variable "backup_rule" {
  type        = any
  description = "A rule object that specifies a scheduled task that is used to back up a selection of resources"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the resources"
  default     = {}
}

variable "advanced_backup_setting" {
  type        = map(string)
  description = "An object that specifies backup options for each resource type."
  default     = {}
}

variable "selection_tag" {
  type        = map(any)
  description = "Tag-based conditions used to specify a set of resources to assign to a backup plan."

}

variable "iam_role_arn" {
  type        = string
  description = "Service role to be used by AWS Backup, created externally"
}

variable "enable_vault_lock_governance" {
  type        = bool
  description = "A variable that allows to enable vault lock in governance mode"
  default     = false
}

variable "create_sns_topic" {
  type        = bool
  description = "SNS topic for vault notifications."
  default     = false
}

variable "backup_vault_events" {
  type        = list(string)
  description = "An array of events that indicate the status of jobs to back up resources to the backup vault."
  default     = ["BACKUP_JOB_FAILED", "BACKUP_JOB_EXPIRED", "S3_BACKUP_OBJECT_FAILED"]
}
