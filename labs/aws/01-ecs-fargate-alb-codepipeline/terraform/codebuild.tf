# CodeBuild: builds the image (running the tests), pushes it to ECR, writes imagedefinitions.json.

resource "aws_codebuild_project" "app" {
  name          = local.codebuild.project_name
  service_role  = aws_iam_role.main["codebuild"].arn
  build_timeout = local.codebuild.timeout_minutes
  description   = "Build and push the ${var.project} image (${var.env})"

  source {
    type      = "CODEPIPELINE"
    buildspec = local.codebuild.buildspec
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type            = "LINUX_CONTAINER"
    compute_type    = local.codebuild.compute_type
    image           = local.codebuild.image
    privileged_mode = local.codebuild.privileged_mode

    environment_variable {
      name  = "ECR_REPOSITORY_URL"
      value = aws_ecr_repository.app.repository_url
    }
    environment_variable {
      name  = "ECR_REGISTRY"
      value = local.ecr.registry
    }
    environment_variable {
      name  = "APP_DIR"
      value = local.codebuild.app_dir
    }
    environment_variable {
      name  = "CONTAINER_NAME"
      value = local.ecs.container.name
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.main["build"].name
    }
  }
}
