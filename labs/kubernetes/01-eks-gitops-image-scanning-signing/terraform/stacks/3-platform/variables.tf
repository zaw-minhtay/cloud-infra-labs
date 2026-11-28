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

# Set with TF_VAR_github_owner, so your username is never written in a file.
variable "github_owner" {
  description = "GitHub user or organization that owns the app and GitOps repositories"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9-]+$", var.github_owner)) && var.github_owner != "your-github-username"
    error_message = "Set github_owner to your GitHub username, e.g. export TF_VAR_github_owner=<your-github-username>."
  }
}

variable "app_repository" {
  description = "Name of the app repository (code, CI, release)"
  type        = string
  default     = "sample-web-app"
}

variable "gitops_repository" {
  description = "Name of the GitOps repository Argo CD reads"
  type        = string
  default     = "eks-platform-gitops"
}

variable "gitops_revision" {
  description = "Branch of the GitOps repository to deploy"
  type        = string
  default     = "main"
}

variable "create_github_oidc_provider" {
  description = "Create GitHub's OIDC provider in this account (false if the account already has one)"
  type        = bool
  default     = true
}

variable "argocd_chart_version" {
  description = "argo-cd Helm chart version (argoproj/argo-helm)"
  type        = string
}

variable "argocd_apps_chart_version" {
  description = "argocd-apps Helm chart version (argoproj/argo-helm)"
  type        = string
}

variable "gatekeeper_chart_version" {
  description = "gatekeeper Helm chart version (open-policy-agent/gatekeeper), equal to Gatekeeper's version"
  type        = string
}

variable "ratify_chart_version" {
  description = "ratify Helm chart version (notaryproject/ratify)"
  type        = string
}

variable "force_destroy" {
  description = "Let terraform destroy delete ECR repositories that still hold images (false in prd)"
  type        = bool
}

variable "deletion_protection" {
  description = "Protect the DynamoDB table from deletion (true in prd)"
  type        = bool
}
