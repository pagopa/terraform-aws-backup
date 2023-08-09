terraform {
  required_version = ">= 1.0.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.45"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.2"
    }

  }
}