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

  default_tags {
    tags = local.common_tags
  }
}

# The account comes from your AWS login; no account ID is written in any file.
data "aws_caller_identity" "current" {}
