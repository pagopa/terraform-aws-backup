terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.13.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}


provider "aws" {
  region = "eu-central-1"
}

provider "aws" {
  alias  = "eu-west-1"
  region = "eu-west-1"
}
