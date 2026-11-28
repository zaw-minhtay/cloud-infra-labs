# One-time setup per AWS account: the S3 bucket that stores that environment's Terraform state.
# Its own state stays local (terraform.tfstate in this folder, git-ignored): keep it until you
# delete the bucket at the end of the lab.

terraform {
  required_version = "~> 1.17"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.74"
    }
  }
}
