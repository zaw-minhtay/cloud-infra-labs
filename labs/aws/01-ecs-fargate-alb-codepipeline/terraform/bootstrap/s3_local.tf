# Names and settings for the Terraform state bucket (same naming rule as the main configuration).

locals {
  s3 = {
    tfstate = {
      # Must match `bucket` in env/<env>/backend.hcl
      name          = "${var.project}-${var.env}-s3-tfstate-${var.account_id}-${var.region}"
      versioning    = "Enabled" # keeps every old state version, so a bad change can be recovered
      force_destroy = var.force_destroy
      policy_file   = "${path.module}/policy/s3/tfstate_bucket_policy.json" # HTTPS only
    }
  }
}
