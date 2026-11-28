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

variable "azs" {
  description = "The two Availability Zones"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "vpc_cidr" {
  description = "VPC address range"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnets (load balancer, NAT gateway), one per AZ"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnets (nodes and pods), one per AZ. Large, because every pod takes a VPC IP"
  type        = list(string)
}
