# Names and settings for the S3 bucket that stores the pipeline's artifacts.

locals {
  s3 = {
    artifacts = {
      # S3 names are global: the account ID and region make this one unique (max 63 characters)
      name = "${local.name_prefix}-s3-artifacts-${local.account_id}-${var.region}"
      # dev/stg: destroy even with objects inside
      force_destroy = var.force_destroy
      # Bucket policy: HTTPS only
      policy_file = "${path.module}/policy/s3/artifacts_bucket_policy.json"
    }
  }
}
