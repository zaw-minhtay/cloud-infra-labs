# Names and settings for the IAM roles (one per job, least privilege).
# The policies themselves are JSON files in policy/iam/; ${...} placeholders are filled in here.

locals {
  iam = {
    policy_dir = "${path.module}/policy/iam"

    roles = {
      # Pull the image, read the DB secret, write logs
      ecs_task_execution = {
        name    = "${local.name_prefix}-role-ecs-task-execution"
        service = "ecs-tasks.amazonaws.com"
      }
      # The app's own AWS access (none needed)
      ecs_task = {
        name    = "${local.name_prefix}-role-ecs-task"
        service = "ecs-tasks.amazonaws.com"
      }
      # Push to this ECR repository
      codebuild = {
        name    = "${local.name_prefix}-role-codebuild"
        service = "codebuild.amazonaws.com"
      }
      # Run the build, update this ECS service
      codepipeline = {
        name    = "${local.name_prefix}-role-codepipeline"
        service = "codepipeline.amazonaws.com"
      }
    }

    ecs_task_execution_managed_policy = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  }

  # Inline policy per role: role key => { policy name, rendered JSON }.
  # Rendered here (not in iam.tf) because each file needs different values, and for_each needs
  # every entry to have the same shape. The ECS task role has none: the app needs no AWS access.
  iam_inline_policies = {
    ecs_task_execution = {
      name = "read-db-secret"
      document = templatefile("${local.iam.policy_dir}/ecs_task_execution_policy.json", {
        db_secret_arn = aws_rds_cluster.main.master_user_secret[0].secret_arn
      })
    }
    codebuild = {
      name = "build-and-push"
      document = templatefile("${local.iam.policy_dir}/codebuild_policy.json", {
        build_log_group_arn  = aws_cloudwatch_log_group.main["build"].arn
        artifacts_bucket_arn = aws_s3_bucket.artifacts.arn
        ecr_repository_arn   = aws_ecr_repository.app.arn
      })
    }
    codepipeline = {
      name = "source-build-deploy"
      document = templatefile("${local.iam.policy_dir}/codepipeline_policy.json", {
        artifacts_bucket_arn    = aws_s3_bucket.artifacts.arn
        connection_arn          = aws_codeconnections_connection.github.arn
        codebuild_project_arn   = aws_codebuild_project.app.arn
        ecs_service_arn         = aws_ecs_service.app.id
        task_execution_role_arn = aws_iam_role.main["ecs_task_execution"].arn
        task_role_arn           = aws_iam_role.main["ecs_task"].arn
      })
    }
  }
}
