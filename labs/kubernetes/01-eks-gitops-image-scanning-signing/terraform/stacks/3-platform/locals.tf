locals {
  # Naming rule: {project}-{env}[-{purpose}], e.g. k8slab01-dev-items, k8slab01-dev-github-ci
  name = "${var.project}-${var.env}"

  app_name      = "sample-web-app"
  app_namespace = "app-${var.env}"

  # The cluster's OIDC issuer without https://, for the one IRSA trust policy
  oidc_issuer = replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")

  tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
    Stack       = "platform"
  }
}
