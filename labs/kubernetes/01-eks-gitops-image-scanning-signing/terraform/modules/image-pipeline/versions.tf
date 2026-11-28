terraform {
  required_version = "~> 1.17"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.74"
    }
    # ECR managed signing isn't in the aws provider yet; the Cloud Control (awscc) provider has it.
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.111"
    }
  }
}
