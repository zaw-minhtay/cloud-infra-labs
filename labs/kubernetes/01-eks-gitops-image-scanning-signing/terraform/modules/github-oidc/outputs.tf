output "ci_role_arn" {
  description = "Role for the CI workflow; set it as the AWS_CI_ROLE_ARN variable in the app repository"
  value       = aws_iam_role.this["ci"].arn
}

output "release_role_arn" {
  description = "Role for the release workflow; set it as the AWS_RELEASE_ROLE_ARN variable in the app repository"
  value       = aws_iam_role.this["release"].arn
}
