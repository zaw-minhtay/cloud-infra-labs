variable "argocd_chart_version" {
  description = "Version of the argo-cd Helm chart (argoproj/argo-helm). The GitOps repository's argocd Application uses the same one"
  type        = string
}

variable "argocd_apps_chart_version" {
  description = "Version of the argocd-apps Helm chart, which creates the root Application"
  type        = string
}

variable "environment" {
  description = "Environment label on this cluster's entry in Argo CD (dev, stg, prd)"
  type        = string
}

variable "gitops_repo_url" {
  description = "HTTPS address of the GitOps repository Argo CD reads"
  type        = string
}

variable "gitops_revision" {
  description = "Branch of the GitOps repository to deploy"
  type        = string
}

variable "cluster_annotations" {
  description = "Values that differ per cluster (registry, cluster name, VPC …), set on the cluster's entry in Argo CD for the ApplicationSets to read"
  type        = map(string)
}
