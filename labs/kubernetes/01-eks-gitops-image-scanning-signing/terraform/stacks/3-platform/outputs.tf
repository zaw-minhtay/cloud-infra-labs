output "ecr_registry" {
  description = "ECR registry address"
  value       = module.image_pipeline.registry
}

output "candidate_repository" {
  description = "ECR repository for every build (scanned)"
  value       = module.image_pipeline.candidate_repository_name
}

output "release_repository" {
  description = "ECR repository for released versions (signed)"
  value       = module.image_pipeline.release_repository_name
}

output "signing_profile_arn" {
  description = "The AWS Signer profile ECR signs with"
  value       = module.image_pipeline.signing_profile_arn
}

output "github_ci_role_arn" {
  description = "Set as the AWS_CI_ROLE_ARN variable in the app repository"
  value       = module.github_oidc.ci_role_arn
}

output "github_release_role_arn" {
  description = "Set as the AWS_RELEASE_ROLE_ARN variable in the app repository"
  value       = module.github_oidc.release_role_arn
}

output "items_table" {
  description = "DynamoDB table of the app"
  value       = aws_dynamodb_table.items.name
}

output "argocd_namespace" {
  description = "Namespace Argo CD runs in"
  value       = module.argocd_bootstrap.namespace
}
