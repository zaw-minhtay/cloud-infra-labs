# prd: bigger nodes, protected from deletion. Its own AWS account.
# For terraform/stacks/3-platform. Your GitHub username comes from TF_VAR_github_owner, never a file.

env                       = "prd"
argocd_chart_version      = "10.18.0"
argocd_apps_chart_version = "2.0.8"
gatekeeper_chart_version  = "3.23.1"
ratify_chart_version      = "1.15.9"
force_destroy             = false
deletion_protection       = true
