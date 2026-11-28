output "cluster_name" {
  description = "The EKS cluster; use it with `aws eks update-kubeconfig --name`"
  value       = module.eks.cluster_name
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = module.eks.cluster_version
}

output "cluster_endpoint" {
  description = "Kubernetes API address"
  value       = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  description = "The cluster's OIDC provider, used by the one IRSA role (Ratify)"
  value       = module.eks.oidc_provider_arn
}
