output "state_bucket" {
  description = "Must match `bucket` in env/<env>/backend.hcl"
  value       = aws_s3_bucket.tfstate.bucket
}
