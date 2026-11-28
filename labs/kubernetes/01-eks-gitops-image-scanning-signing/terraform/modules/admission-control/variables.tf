variable "name_prefix" {
  description = "Start of every name, e.g. k8slab01-dev"
  type        = string
}

variable "gatekeeper_chart_version" {
  description = "Version of the gatekeeper Helm chart (open-policy-agent/gatekeeper); it is also Gatekeeper's version"
  type        = string
}

variable "ratify_chart_version" {
  description = "Version of the ratify Helm chart (notaryproject/ratify)"
  type        = string
}

variable "release_repository_url" {
  description = "The release repository, <registry>/<name>: the only repository Ratify checks signatures for"
  type        = string
}

variable "signing_profile_arn" {
  description = "The AWS Signer profile ECR signs with: the only signer Ratify trusts"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider, for Ratify's IRSA role"
  type        = string
}

variable "oidc_issuer" {
  description = "The cluster's OIDC issuer without https://, for Ratify's IRSA trust policy"
  type        = string
}
