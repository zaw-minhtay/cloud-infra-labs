# Names and settings for the S3 bucket that stores the pipeline's artifacts.

locals {
  s3 = {
    artifacts = {
      # S3 names are global: the account ID and region make this one unique (max 63 characters)
      name          = "${local.name_prefix}-s3-artifacts-${local.account_id}-${var.region}"
      force_destroy = var.force_destroy # dev/stg: destroy even with objects inside
    }
  }
}
