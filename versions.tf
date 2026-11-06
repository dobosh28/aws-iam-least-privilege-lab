# Pin Terraform and the AWS provider so builds are reproducible.
terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile # a named CLI profile; keys never live in this repo

  # Tag everything this project creates so it's easy to find (and clean up).
  default_tags {
    tags = {
      Project   = "aws-security-baseline"
      ManagedBy = "terraform"
    }
  }
}
