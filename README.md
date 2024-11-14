# AWS Backup Terraform module

Terraform module which creates Backup resources on AWS:
* Backup vault.
* Backup vault lock.
* KMS key per vault.
* Backup plan.
* Backup selection (mainly tag).

## Usage

Backup all resources that have **tag** __DataClassification__ equals to __PII customer data__.

One daily rule starts every day at 2:00 PM UTC and deletes each snapshot older than 14 days.

The **default rule** instead starts daily at 5:00 AM UTC with no expiration. 


```hcl
module "aws_backup" {
  source  = "pagopa/backup/aws"
  version = "1.3.4"
  name         = "backup"
  iam_role_arn = aws_iam_role.example.arn

  selection_tag = {
    key   = "DataClassification"
    value = "PII customer data"
  }

  enable_vault_lock_governance = false

  backup_rule = [{
    rule_name         = "backup_daily_rule"
    schedule          = "cron(0 14 * * ? *)"
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
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_backup_plan.backup_plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_selection.backup_selection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_vault.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_backup_vault_lock_configuration.vault_lock](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_lock_configuration) | resource |
| [aws_kms_key.kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [random_id.salt](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.kms_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backup_rule"></a> [backup\_rule](#input\_backup\_rule) | A rule object that specifies a scheduled task that is used to back up a selection of resources | `any` | n/a | yes |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | Service role to be used by AWS Backup, created externally | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the supporting resources | `string` | n/a | yes |
| <a name="input_selection_tag"></a> [selection\_tag](#input\_selection\_tag) | Tag-based conditions used to specify a set of resources to assign to a backup plan. | `map(any)` | n/a | yes |
| <a name="input_advanced_backup_setting"></a> [advanced\_backup\_setting](#input\_advanced\_backup\_setting) | An object that specifies backup options for each resource type. | `map(string)` | `{}` | no |
| <a name="input_enable_vault_lock_governance"></a> [enable\_vault\_lock\_governance](#input\_enable\_vault\_lock\_governance) | A variable that allows to enable vault lock in governance mode | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backup_plan_arn"></a> [backup\_plan\_arn](#output\_backup\_plan\_arn) | Backup Plan ARN |
| <a name="output_backup_plan_version"></a> [backup\_plan\_version](#output\_backup\_plan\_version) | Unique, randomly generated, Unicode, UTF-8 encoded string that serves as the version ID of the backup plan |
| <a name="output_backup_vault_arn"></a> [backup\_vault\_arn](#output\_backup\_vault\_arn) | Backup Vault ARN |
| <a name="output_backup_vault_id"></a> [backup\_vault\_id](#output\_backup\_vault\_id) | Backup Vault ID |


