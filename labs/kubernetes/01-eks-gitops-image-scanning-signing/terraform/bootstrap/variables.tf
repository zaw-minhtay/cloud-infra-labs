variable "project" {
  description = "Short project code, the first part of every resource name"
  type        = string
  default     = "k8slab01"
}

variable "env" {
  description = "Environment: dev, stg, or prd (each in its own AWS account)"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prd"], var.env)
    error_message = "env must be dev, stg, or prd."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "force_destroy" {
  description = "Let terraform destroy delete the bucket with every state version in it (false in prd)"
  type        = bool
}
