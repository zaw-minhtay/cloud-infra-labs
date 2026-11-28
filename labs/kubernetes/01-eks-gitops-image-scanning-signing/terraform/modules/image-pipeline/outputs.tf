output "registry" {
  description = "The ECR registry address (contains the account ID: kept out of Git)"
  value       = local.registry
}

output "candidate_repository_name" {
  description = "Repository for every build (scanned, not signed)"
  value       = aws_ecr_repository.candidate.name
}

output "candidate_repository_arn" {
  description = "ARN of the candidate repository"
  value       = aws_ecr_repository.candidate.arn
}

output "release_repository_name" {
  description = "Repository for released versions (signed, immutable tags)"
  value       = aws_ecr_repository.release.name
}

output "release_repository_arn" {
  description = "ARN of the release repository"
  value       = aws_ecr_repository.release.arn
}

output "signing_profile_arn" {
  description = "The Signer profile ECR signs with; the cluster trusts only this one"
  value       = aws_signer_signing_profile.release.arn
}
