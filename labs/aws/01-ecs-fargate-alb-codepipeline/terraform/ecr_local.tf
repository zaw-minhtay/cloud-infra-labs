# Names and settings for the ECR repository.

locals {
  ecr = {
    name         = "${local.name_prefix}-app"
    keep_images  = 10                # older images expire automatically
    force_delete = var.force_destroy # dev/stg: destroy even with images inside
    registry     = "${local.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  }
}
