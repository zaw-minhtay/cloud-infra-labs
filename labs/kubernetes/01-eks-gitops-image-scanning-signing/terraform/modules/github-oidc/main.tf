# GitHub Actions gets short-lived AWS credentials through OIDC: no AWS keys are stored in GitHub.
# One IAM role per workflow, each usable only by the app repository, and only from main (CI) or
# from a v* tag (release).

# GitHub's OIDC identity provider. An account can have only one for this URL.
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_provider ? 0 : 1

  url = "https://token.actions.githubusercontent.com"
}

locals {
  provider_arn = var.create_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn

  # Which runs of the app repository may use each role (the token's "sub" claim).
  subjects = {
    ci      = "repo:${var.repository}:ref:refs/heads/main"
    release = "repo:${var.repository}:ref:refs/tags/v*"
  }

  ecr_push = [
    "ecr:BatchCheckLayerAvailability",
    "ecr:InitiateLayerUpload",
    "ecr:UploadLayerPart",
    "ecr:CompleteLayerUpload",
    "ecr:PutImage",
    "ecr:BatchGetImage",
  ]
}

data "aws_iam_policy_document" "trust" {
  for_each = local.subjects

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [each.value]
    }
  }
}

# CI: push each build to candidate. Nothing else.
data "aws_iam_policy_document" "ci" {
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid       = "PushCandidate"
    actions   = local.ecr_push
    resources = [var.candidate_repository_arn]
  }
}

# Release: read a build and its scan result from candidate, copy it to release, and let ECR sign
# it there (managed signing signs with the pusher's signer:SignPayload permission).
data "aws_iam_policy_document" "release" {
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "ReadCandidateAndScan"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeImages",
      "ecr:DescribeImageScanFindings",
    ]
    resources = [var.candidate_repository_arn]
  }

  statement {
    sid       = "PushRelease"
    actions   = concat(local.ecr_push, ["ecr:DescribeImages", "ecr:DescribeImageSigningStatus"])
    resources = [var.release_repository_arn]
  }

  statement {
    sid       = "SignOnPush"
    actions   = ["signer:SignPayload"]
    resources = [var.signing_profile_arn]
  }
}

locals {
  permissions = {
    ci      = data.aws_iam_policy_document.ci.json
    release = data.aws_iam_policy_document.release.json
  }
}

resource "aws_iam_role" "this" {
  for_each = local.subjects

  name               = "${var.name_prefix}-github-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.trust[each.key].json
}

resource "aws_iam_role_policy" "this" {
  for_each = local.subjects

  name   = each.key
  role   = aws_iam_role.this[each.key].id
  policy = local.permissions[each.key]
}
