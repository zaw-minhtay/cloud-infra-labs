# GitHub connection and the pipeline: Source (GitHub) -> Build (CodeBuild) -> Deploy (ECS).

# Created in PENDING state. You finish it once in the console (setup/3-pipeline.md):
# it installs the "AWS Connector for GitHub" app on your repository.
resource "aws_codeconnections_connection" "github" {
  name          = local.codepipeline.connection_name
  provider_type = "GitHub"
}

resource "aws_codepipeline" "app" {
  name          = local.codepipeline.pipeline_name
  role_arn      = aws_iam_role.main["codepipeline"].arn
  pipeline_type = "V2"

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.artifacts.bucket
  }

  # Start only on pushes to this environment's branch that change the app or buildspec/buildspec.yml
  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      push {
        branches {
          includes = [local.codepipeline.branch]
        }
        file_paths {
          includes = local.codepipeline.trigger_paths
        }
      }
    }
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      namespace        = "SourceVariables" # exposes #{SourceVariables.CommitId} to later stages
      output_artifacts = [local.codepipeline.artifacts.source]

      configuration = {
        ConnectionArn    = aws_codeconnections_connection.github.arn
        FullRepositoryId = local.codepipeline.repository
        BranchName       = local.codepipeline.branch
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = [local.codepipeline.artifacts.source]
      output_artifacts = [local.codepipeline.artifacts.build]

      configuration = {
        ProjectName = aws_codebuild_project.app.name
        # The commit ID becomes the image tag (see buildspec/buildspec.yml)
        EnvironmentVariables = jsonencode([
          { name = "COMMIT_ID", value = "#{SourceVariables.CommitId}", type = "PLAINTEXT" },
        ])
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = [local.codepipeline.artifacts.build]

      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.app.name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
