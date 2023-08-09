terraform {
  required_version = ">= 1.0.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}


provider "aws" {
  region = "eu-west-1"
}
