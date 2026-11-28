# The image supply chain: two ECR repositories, Amazon Inspector scanning, and ECR managed
# signing with AWS Signer. A build lands in candidate; a release copies it to release, where it
# is signed. So "signed" also means "passed the scan".

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  candidate_repository = "${var.name_prefix}/candidate/${var.app_name}"
  release_repository   = "${var.name_prefix}/release/${var.app_name}"
  registry             = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.region}.amazonaws.com"
}

# Every CI build lands here, tagged with its commit ID, and is scanned on push. Not signed.
resource "aws_ecr_repository" "candidate" {
  name                 = local.candidate_repository
  image_tag_mutability = "MUTABLE" # a re-run of CI for the same commit pushes the same tag again
  force_delete         = var.force_destroy
}

resource "aws_ecr_lifecycle_policy" "candidate" {
  repository = aws_ecr_repository.candidate.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last ${var.candidate_images_to_keep} builds"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.candidate_images_to_keep
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# Only released versions (1.2.0), copied from candidate after a clean scan. ECR signs every
# image pushed here, and a tag can never be overwritten. No lifecycle policy: the signatures
# are stored next to the images, and old releases must stay deployable for a rollback.
resource "aws_ecr_repository" "release" {
  name                 = local.release_repository
  image_tag_mutability = "IMMUTABLE"
  force_delete         = var.force_destroy
}

# Amazon Inspector scans the ECR images in this account (ECR enhanced scanning).
resource "aws_inspector2_enabler" "ecr" {
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["ECR"]
}

resource "aws_ecr_registry_scanning_configuration" "this" {
  scan_type = "ENHANCED"

  # candidate: scanned once, on push. The release workflow reads this result.
  rule {
    scan_frequency = "SCAN_ON_PUSH"
    repository_filter {
      filter      = "${var.name_prefix}/candidate/*"
      filter_type = "WILDCARD"
    }
  }

  # release: rescanned whenever a new CVE affects an image that was already released.
  rule {
    scan_frequency = "CONTINUOUS_SCAN"
    repository_filter {
      filter      = "${var.name_prefix}/release/*"
      filter_type = "WILDCARD"
    }
  }

  depends_on = [aws_inspector2_enabler.ecr]
}

# AWS Signer profile for container images (Notation format). A Signer profile can't be deleted,
# only cancelled, so the name gets a random suffix and a new run never clashes with an old one.
# Signer names allow only letters, digits, and underscores.
resource "aws_signer_signing_profile" "release" {
  name_prefix = "${replace(var.name_prefix, "-", "_")}_release_"
  platform_id = "Notation-OCI-SHA384-ECDSA"
}

# ECR managed signing: every image pushed to a release repository is signed with the profile.
resource "awscc_ecr_signing_configuration" "this" {
  rules = [{
    signing_profile_arn = aws_signer_signing_profile.release.arn
    repository_filters = [{
      filter      = "${var.name_prefix}/release/*"
      filter_type = "WILDCARD_MATCH"
    }]
  }]
}
