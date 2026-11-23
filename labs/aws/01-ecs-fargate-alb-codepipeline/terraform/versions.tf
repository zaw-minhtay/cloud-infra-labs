terraform {
  required_version = "~> 1.17"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.73"
    }
  }

  # Settings come from env/<env>/backend.hcl:
  #   terraform init -backend-config=env/dev/backend.hcl
  backend "s3" {}
}

provider "aws" {
  region = var.region

  # Each environment lives in its own AWS account. This makes Terraform refuse to run if your
  # credentials point at a different account than the one in env/<env>/terraform.tfvars.
  allowed_account_ids = [var.account_id]

  default_tags {
    tags = local.common_tags
  }
}

data "aws_caller_identity" "current" {}
