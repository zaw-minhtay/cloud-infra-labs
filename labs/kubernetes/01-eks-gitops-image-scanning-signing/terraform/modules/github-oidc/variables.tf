variable "name_prefix" {
  description = "Start of every name, e.g. k8slab01-dev"
  type        = string
}

variable "repository" {
  description = "The app repository allowed to use the roles, as owner/name"
  type        = string
}

variable "create_provider" {
  description = "Create GitHub's OIDC provider. An account can have only one: false if it already exists"
  type        = bool
}

variable "candidate_repository_arn" {
  description = "ECR repository CI pushes every build to"
  type        = string
}

variable "release_repository_arn" {
  description = "ECR repository the release workflow copies released versions to"
  type        = string
}

variable "signing_profile_arn" {
  description = "Signer profile ECR signs with; whoever pushes to release needs signer:SignPayload on it"
  type        = string
}
