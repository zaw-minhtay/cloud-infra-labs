output "state_bucket" {
  description = "The state bucket; pass it to `terraform init` in each stack"
  value       = aws_s3_bucket.tfstate.bucket
}
