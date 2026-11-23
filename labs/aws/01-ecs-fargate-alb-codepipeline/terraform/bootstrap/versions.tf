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
  region              = var.region
  allowed_account_ids = [var.account_id]

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.env
      ManagedBy   = "terraform"
    }
  }
}
