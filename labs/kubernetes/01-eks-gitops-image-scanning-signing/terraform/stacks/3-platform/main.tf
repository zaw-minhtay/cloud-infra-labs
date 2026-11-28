# ---- Images: ECR candidate + release, Inspector scanning, AWS Signer, ECR managed signing ----
module "image_pipeline" {
  source = "../../modules/image-pipeline"

  name_prefix   = local.name
  app_name      = local.app_name
  force_destroy = var.force_destroy
}

# ---- GitHub Actions access to AWS: OIDC, one role for CI and one for releases ----
module "github_oidc" {
  source = "../../modules/github-oidc"

  name_prefix              = local.name
  repository               = "${var.github_owner}/${var.app_repository}"
  create_provider          = var.create_github_oidc_provider
  candidate_repository_arn = module.image_pipeline.candidate_repository_arn
  release_repository_arn   = module.image_pipeline.release_repository_arn
  signing_profile_arn      = module.image_pipeline.signing_profile_arn
}

# ---- The app's data ----
resource "aws_dynamodb_table" "items" {
  name         = "${local.name}-items"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  deletion_protection_enabled = var.deletion_protection
}

# ---- Pod access to AWS through EKS Pod Identity: one role per service account ----

# The app: read and write its one table, nothing else.
module "app_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.11.0"

  name                 = "${local.name}-${local.app_name}"
  attach_custom_policy = true
  policy_statements = [{
    sid       = "ItemsTable"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:Scan"]
    resources = [aws_dynamodb_table.items.arn]
  }]

  associations = {
    app = {
      cluster_name    = data.aws_eks_cluster.this.name
      namespace       = local.app_namespace
      service_account = local.app_name
    }
  }
}

# The AWS Load Balancer Controller: manage load balancers for the Ingresses.
module "lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.11.0"

  name                            = "${local.name}-aws-lb-controller"
  attach_aws_lb_controller_policy = true

  associations = {
    controller = {
      cluster_name    = data.aws_eks_cluster.this.name
      namespace       = "platform"
      service_account = "aws-load-balancer-controller"
    }
  }
}

# ---- Admission control: Gatekeeper + Ratify (and Ratify's IRSA role) ----
# Only images signed by our Signer profile, from our release repository, may run in app-*.
module "admission_control" {
  source = "../../modules/admission-control"

  name_prefix              = local.name
  gatekeeper_chart_version = var.gatekeeper_chart_version
  ratify_chart_version     = var.ratify_chart_version
  release_repository_url   = "${module.image_pipeline.registry}/${module.image_pipeline.release_repository_name}"
  signing_profile_arn      = module.image_pipeline.signing_profile_arn
  oidc_provider_arn        = data.aws_iam_openid_connect_provider.cluster.arn
  oidc_issuer              = local.oidc_issuer
}

# ---- Argo CD: install once, register this cluster with its values, create the root Application ----
module "argocd_bootstrap" {
  source = "../../modules/argocd-bootstrap"

  argocd_chart_version      = var.argocd_chart_version
  argocd_apps_chart_version = var.argocd_apps_chart_version
  environment               = var.env
  gitops_repo_url           = "https://github.com/${var.github_owner}/${var.gitops_repository}.git"
  gitops_revision           = var.gitops_revision

  # Read by the ApplicationSets in the GitOps repository; never written in Git.
  cluster_annotations = {
    "ecr-registry"       = module.image_pipeline.registry
    "release-repository" = module.image_pipeline.release_repository_name
    "cluster-name"       = data.aws_eks_cluster.this.name
    "vpc-id"             = data.aws_vpc.this.id
    "region"             = var.region
  }

  # Gatekeeper and Ratify must be running before Argo CD syncs the policies and the app.
  depends_on = [module.admission_control]
}
