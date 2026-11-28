# Admission control for the app namespaces: Gatekeeper checks every new Pod against the policies
# in the GitOps repository, and asks Ratify whether its image is signed by our AWS Signer profile.
#
# Terraform installs these two, not Argo CD: the Ratify chart makes its TLS certificate with Helm
# functions and hooks (genCA, lookup) that only a real Helm install runs. The policies themselves
# are in the GitOps repository, and Argo CD manages them.

locals {
  namespace              = "gatekeeper-system"
  ratify_service_account = "ratify-admin"
}

# OPA Gatekeeper: the admission webhook, and the audit that re-checks running Pods every minute.
# If Gatekeeper itself is down, its webhook lets requests through (the chart's default), so it
# can't stop the whole cluster; the audit then reports any Pod that breaks a rule.
resource "helm_release" "gatekeeper" {
  name             = "gatekeeper"
  namespace        = local.namespace
  create_namespace = true
  repository       = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart            = "gatekeeper"
  version          = var.gatekeeper_chart_version

  values = [yamlencode({
    # 2 instead of the chart's 3: fits the dev nodes, and one can still go down.
    replicas = 2

    # The settings Ratify's documentation gives: ask external data providers (Ratify) …
    enableExternalData = true
    # … wait for an answer as long as Ratify may take (its provider timeout is 5 seconds) …
    validatingWebhookTimeoutSeconds = 5
    # … and reuse an answer for 10 seconds only, so a revoked signature soon stops being accepted.
    externaldataProviderResponseCacheTTL = "10s"
  })]
}

# Ratify: checks signatures for Gatekeeper. It trusts AWS Signer's root certificate, and under it
# only our signing profile, for images in our release repository. If Ratify can't answer, the
# signature policy denies the Pod.
resource "helm_release" "ratify" {
  name       = "ratify"
  namespace  = local.namespace
  repository = "https://notaryproject.github.io/ratify"
  chart      = "ratify"
  version    = var.ratify_chart_version

  values = [yamlencode({
    # From https://d2hvyiie56hcat.cloudfront.net/aws-signer-notation-root.cert (AWS Signer Code
    # Signing Root CA G1, SHA-256 fingerprint 90:A8:7D:05:…:47:3F).
    notationCerts = [file("${path.module}/aws-signer-notation-root.cert")]

    notation = {
      trustPolicies = [{
        name           = "release"
        registryScopes = [var.release_repository_url]
        # strict: the signature must be intact, not expired, and not revoked (asked of AWS Signer).
        level             = "strict"
        trustStores       = ["signingAuthority:notationCerts[0]"]
        trustedIdentities = [var.signing_profile_arn]
      }]
    }

    # Only Notation signatures (AWS Signer) are used in this lab.
    cosign = {
      enabled = false
    }

    # Off: Ratify would rewrite image tags to digests in every namespace, which Argo CD sees as
    # drift. The app's manifests pin the digest already, and a Gatekeeper policy requires it.
    provider = {
      enableMutation = false
    }

    serviceAccount = {
      create = true
      name   = local.ratify_service_account
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.ratify.arn
      }
    }

    # Log in to ECR with that role, to read images and their signatures.
    oras = {
      authProviders = {
        awsEcrBasicEnabled = true
      }
    }

    featureFlags = {
      # Ratify makes and renews its own TLS certificate, and gives Gatekeeper the CA.
      RATIFY_CERT_ROTATION = true
      # Lets Ratify download the AWS Signer plugin (a Verifier in the GitOps repository).
      RATIFY_EXPERIMENTAL_DYNAMIC_PLUGINS = true
    }

    # Which Gatekeeper API versions Ratify's objects use.
    gatekeeper = {
      version = var.gatekeeper_chart_version
    }
  })]

  depends_on = [
    helm_release.gatekeeper,
    aws_iam_role_policy_attachment.ratify_ecr,
    aws_iam_role_policy.ratify_signer,
  ]
}

# ---- Ratify's IAM role: the one IRSA role in this lab ----
# Ratify's ECR login reads only the IRSA settings (AWS_ROLE_ARN, AWS_WEB_IDENTITY_TOKEN_FILE),
# not EKS Pod Identity's, so this role trusts the cluster's OIDC provider.
data "aws_iam_policy_document" "ratify_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer}:sub"
      values   = ["system:serviceaccount:${local.namespace}:${local.ratify_service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ratify" {
  name               = "${var.name_prefix}-ratify"
  assume_role_policy = data.aws_iam_policy_document.ratify_trust.json
}

# Read images and their signatures from ECR (the managed policy Ratify's AWS guide uses).
resource "aws_iam_role_policy_attachment" "ratify_ecr" {
  role       = aws_iam_role.ratify.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Ask AWS Signer whether a signature, its profile, or its certificate has been revoked.
data "aws_iam_policy_document" "ratify_signer" {
  statement {
    sid       = "SignerRevocationStatus"
    actions   = ["signer:GetRevocationStatus"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ratify_signer" {
  name   = "signer-revocation"
  role   = aws_iam_role.ratify.id
  policy = data.aws_iam_policy_document.ratify_signer.json
}
