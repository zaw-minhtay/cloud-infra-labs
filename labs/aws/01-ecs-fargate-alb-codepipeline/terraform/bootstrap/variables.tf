# Read from the same env/<env>/terraform.tfvars as the main configuration:
#   terraform apply -var-file=../env/dev/terraform.tfvars
# Terraform warns about the other variables in that file; that is expected here.

variable "project" {
  description = "Short project code, the first part of every resource name"
  type        = string
  default     = "awslab01"
}

variable "env" {
  description = "Environment: dev, stg, or prd"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prd"], var.env)
    error_message = "env must be dev, stg, or prd."
  }
}

variable "account_id" {
  description = "The AWS account ID of this environment"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be your 12-digit AWS account ID. Edit env/<env>/terraform.tfvars."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "force_destroy" {
  description = "Let terraform destroy delete the bucket with all state versions (false in prd)"
  type        = bool
}
