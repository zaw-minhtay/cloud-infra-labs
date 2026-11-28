# Inputs. Values that differ per environment are set in env/<env>/terraform.tfvars.

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

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "azs" {
  description = "The two Availability Zones. The Aurora writer goes in the first one."
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "vpc_cidr" {
  description = "VPC address range"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnets (ALB), one per AZ"
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "Private app subnets (ECS tasks, VPC endpoints), one per AZ"
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "Private DB subnets (Aurora), one per AZ"
  type        = list(string)
}

variable "github_repository" {
  description = "Your GitHub repository as owner/name"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", var.github_repository)) && !startswith(var.github_repository, "your-github-username/")
    error_message = "Set github_repository to your own owner/name in env/<env>/terraform.tfvars."
  }
}

variable "github_branch" {
  description = "Branch this environment's pipeline deploys"
  type        = string
}

variable "app_desired_count" {
  description = "Number of ECS tasks. Use 0 on the very first apply, before any image exists."
  type        = number
}

variable "task_cpu" {
  description = "Fargate task CPU units (512 = 0.5 vCPU)"
  type        = number
}

variable "task_memory" {
  description = "Fargate task memory in MiB"
  type        = number
}

variable "db_instance_class" {
  description = "Aurora instance class for the writer and the reader"
  type        = string
}

variable "db_backup_retention_days" {
  description = "Days of Aurora automated backups (point-in-time restore)"
  type        = number
}

variable "deletion_protection" {
  description = "Protect the ALB and Aurora from deletion (true in prd)"
  type        = bool
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
}

variable "force_destroy" {
  description = "Let terraform destroy delete non-empty buckets/repositories and skip the final DB snapshot (false in prd)"
  type        = bool
}
