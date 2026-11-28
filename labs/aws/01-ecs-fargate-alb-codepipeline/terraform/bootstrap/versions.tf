# One-time setup per AWS account: the S3 bucket that stores that environment's Terraform state.
# Its own state stays local (terraform.tfstate in this folder, git-ignored). Keep it until you
# destroy the bucket at the very end (setup/5-clean-up.md).

terraform {
  required_version = "~> 1.17"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.73"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.env
      ManagedBy   = "terraform"
    }
  }
}

# The account comes from your AWS login; no account ID is written in any file.
data "aws_caller_identity" "current" {}
