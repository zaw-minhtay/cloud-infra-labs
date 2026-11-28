# Names and settings for the Terraform state bucket (same naming rule as the main configuration).

locals {
  account_id = data.aws_caller_identity.current.account_id

  s3 = {
    tfstate = {
      # S3 names are global: the account ID and region make this one unique.
      # Must match the `bucket` passed to `terraform init` in the main configuration (step 8).
      name          = "${var.project}-${var.env}-s3-tfstate-${local.account_id}-${var.region}"
      versioning    = "Enabled" # keeps every old state version, so a bad change can be recovered
      force_destroy = var.force_destroy
      policy_file   = "${path.module}/policy/s3/tfstate_bucket_policy.json" # HTTPS only
    }
  }
}
