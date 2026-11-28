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

variable "kubernetes_version" {
  description = "EKS Kubernetes version (one in standard support)"
  type        = string
}

variable "node_instance_types" {
  description = "Instance types for the managed node group"
  type        = list(string)
}

variable "node_min_size" {
  description = "Fewest nodes"
  type        = number
}

variable "node_max_size" {
  description = "Most nodes"
  type        = number
}

variable "node_desired_size" {
  description = "Nodes to run now"
  type        = number
}

# Set with TF_VAR_admin_cidrs, so your IP address is never written in a file.
variable "admin_cidrs" {
  description = "The only addresses the public Kubernetes API endpoint accepts: your IP as a /32"
  type        = list(string)

  validation {
    condition     = length(var.admin_cidrs) > 0 && alltrue([for c in var.admin_cidrs : can(cidrhost(c, 0))])
    error_message = "Set admin_cidrs to your IP address as a CIDR, e.g. export TF_VAR_admin_cidrs='[\"203.0.113.10/32\"]'."
  }
}
