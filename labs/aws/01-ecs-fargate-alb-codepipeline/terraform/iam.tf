# IAM roles. Every permission is limited to this lab's own resources where AWS allows it.

# ---- Roles and their trust policies (which AWS service can use each role) ---------------

data "aws_iam_policy_document" "trust" {
  for_each = local.iam.roles

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = [each.value.service]
    }
  }
}

resource "aws_iam_role" "main" {
  for_each = local.iam.roles

  name               = each.value.name
  assume_role_policy = data.aws_iam_policy_document.trust[each.key].json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.main["ecs_task_execution"].name
  policy_arn = local.iam.ecs_task_execution_managed_policy
}

resource "aws_iam_role_policy" "main" {
  for_each = local.iam_inline_policies

  name   = each.value.name
  role   = aws_iam_role.main[each.key].id
  policy = each.value.document
}

# ---- Permission documents (one per role, because their statements differ) ---------------

# ECS task execution: read this one database secret (image pull and logs come from the managed policy)
data "aws_iam_policy_document" "ecs_task_execution" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.main.master_user_secret[0].secret_arn]
  }
}

# CodeBuild: write build logs, read/write pipeline artifacts, push to this ECR repository
data "aws_iam_policy_document" "codebuild" {
  statement {
    sid       = "BuildLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.main["build"].arn}:*"]
  }
  statement {
    sid       = "PipelineArtifacts"
    actions   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
    resources = ["${aws_s3_bucket.artifacts.arn}/*"]
  }
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"] # this action does not support resource-level permissions
  }
  statement {
    sid       = "EcrPush"
    actions   = local.iam.ecr_push_actions
    resources = [aws_ecr_repository.app.arn]
  }
}

# CodePipeline: read the repo, run the build, deploy to this ECS service
data "aws_iam_policy_document" "codepipeline" {
  statement {
    sid = "PipelineArtifacts"
    actions = [
      "s3:GetBucketVersioning",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
    ]
    resources = [aws_s3_bucket.artifacts.arn, "${aws_s3_bucket.artifacts.arn}/*"]
  }
  statement {
    sid       = "UseGitHubConnection"
    actions   = ["codeconnections:UseConnection", "codestar-connections:UseConnection"]
    resources = [aws_codeconnections_connection.github.arn]
  }
  statement {
    sid       = "RunBuild"
    actions   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
    resources = [aws_codebuild_project.app.arn]
  }
  statement {
    sid       = "DeployService"
    actions   = ["ecs:DescribeServices", "ecs:UpdateService"]
    resources = [aws_ecs_service.app.id] # the service ARN
  }
  statement {
    sid = "RegisterTaskDefinition"
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:TagResource",
    ]
    resources = ["*"] # these actions do not support resource-level permissions
  }
  statement {
    sid       = "PassTaskRoles"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.main["ecs_task_execution"].arn, aws_iam_role.main["ecs_task"].arn]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}
