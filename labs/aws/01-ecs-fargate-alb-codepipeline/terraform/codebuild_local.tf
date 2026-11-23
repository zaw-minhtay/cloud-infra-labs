# Names and settings for the CodeBuild project (the pipeline's Build stage).

locals {
  codebuild = {
    project_name    = "${local.name_prefix}-build"
    image           = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
    compute_type    = "BUILD_GENERAL1_SMALL"
    privileged_mode = true # needed to run docker build
    timeout_minutes = 30
    buildspec       = "${local.lab_path}/terraform/buildspec/buildspec.yml"
    app_dir         = "${local.lab_path}/app"
  }
}
