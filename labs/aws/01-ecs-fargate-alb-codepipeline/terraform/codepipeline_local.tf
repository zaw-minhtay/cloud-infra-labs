# Names and settings for the GitHub connection and the pipeline (one pipeline per environment).

locals {
  codepipeline = {
    connection_name = "${local.name_prefix}-github" # max 32 characters
    pipeline_name   = "${local.name_prefix}-pipeline"
    repository      = var.github_repository
    branch          = var.github_branch # dev: main, stg: release/stg, prd: release/prd

    # Only changes to the app or the build instructions start the pipeline
    trigger_paths = [
      "${local.lab_path}/app/**",
      "${local.lab_path}/terraform/buildspec/buildspec.yml",
    ]

    artifacts = {
      source = "source"
      build  = "build"
    }
  }
}
