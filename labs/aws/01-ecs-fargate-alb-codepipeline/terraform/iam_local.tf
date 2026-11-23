# Names and settings for the IAM roles (one per job, least privilege).

locals {
  iam = {
    roles = {
      ecs_task_execution = { name = "${local.name_prefix}-role-ecs-task-execution", service = "ecs-tasks.amazonaws.com" } # pull image, read DB secret, write logs
      ecs_task           = { name = "${local.name_prefix}-role-ecs-task", service = "ecs-tasks.amazonaws.com" }           # the app's own AWS access (none needed)
      codebuild          = { name = "${local.name_prefix}-role-codebuild", service = "codebuild.amazonaws.com" }          # push to this ECR repository
      codepipeline       = { name = "${local.name_prefix}-role-codepipeline", service = "codepipeline.amazonaws.com" }    # run the build, update this ECS service
    }

    ecs_task_execution_managed_policy = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

    ecr_push_actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
  }

  # Which inline policy each role gets: role key => { policy name, policy document (in iam.tf) }.
  # The ECS task role has none on purpose: the app needs no AWS permissions.
  iam_inline_policies = {
    ecs_task_execution = { name = "read-db-secret", document = data.aws_iam_policy_document.ecs_task_execution.json }
    codebuild          = { name = "build-and-push", document = data.aws_iam_policy_document.codebuild.json }
    codepipeline       = { name = "source-build-deploy", document = data.aws_iam_policy_document.codepipeline.json }
  }
}
