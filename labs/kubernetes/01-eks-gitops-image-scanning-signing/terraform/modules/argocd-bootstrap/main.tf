# Installs Argo CD once and points it at the GitOps repository. From then on, everything in the
# cluster (Argo CD's own upgrades included) comes from Git.

locals {
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  in_cluster = "https://kubernetes.default.svc"
}

# Argo CD itself. After this first install, the argocd Application in the GitOps repository
# manages it, so Terraform ignores later changes instead of fighting over them.
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = local.namespace
  create_namespace = true
  repository       = local.repository
  chart            = "argo-cd"
  version          = var.argocd_chart_version

  lifecycle {
    ignore_changes = all
  }
}

# This cluster's entry in Argo CD: an environment label, and the values that differ per cluster
# as annotations. The ApplicationSets read them while creating each Application, so nothing
# account-specific (the ECR address) is ever written in Git.
resource "kubernetes_secret_v1" "in_cluster" {
  metadata {
    name      = "in-cluster"
    namespace = local.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
      "environment"                    = var.environment
    }
    # Plus the GitOps repository's address and branch, which every ApplicationSet reads.
    annotations = merge(var.cluster_annotations, {
      "gitops-repo-url" = var.gitops_repo_url
      "gitops-revision" = var.gitops_revision
    })
  }

  data = {
    name   = "in-cluster"
    server = local.in_cluster
    config = jsonencode({
      tlsClientConfig = {
        insecure = false
      }
    })
  }

  depends_on = [helm_release.argocd]
}

# The root Application (app-of-apps): it syncs apps/ in the GitOps repository, where the
# AppProjects and the ApplicationSets create one Application per namespace.
resource "helm_release" "root_app" {
  name       = "argocd-root"
  namespace  = local.namespace
  repository = local.repository
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version

  values = [yamlencode({
    applications = {
      root = {
        namespace = local.namespace
        project   = "default"
        source = {
          repoURL        = var.gitops_repo_url
          targetRevision = var.gitops_revision
          path           = "apps"
        }
        destination = {
          server    = local.in_cluster
          namespace = local.namespace
        }
        syncPolicy = {
          automated = {
            prune    = true
            selfHeal = true
          }
        }
      }
    }
  })]

  depends_on = [kubernetes_secret_v1.in_cluster]
}
