# Naming rule for every AWS resource in this lab:
#
#   {project}-{env}-{resource}[-{purpose}][-{az}]      e.g. awslab01-dev-sg-app, awslab01-dev-subnet-app-1a
#
# - lowercase letters, digits, and hyphens only
# - {resource} uses AWS's own ID prefixes where they exist: vpc, subnet, igw, rtb, vpce, sg
# - globally unique names (S3) also end with the account ID and region
# Every *_local.tf builds its names from local.name_prefix.

locals {
  name_prefix = "${var.project}-${var.env}"
  account_id  = data.aws_caller_identity.current.account_id

  # "ap-northeast-1a" -> "1a", used as the last part of per-AZ names
  az_suffix = [for az in var.azs : substr(az, length(az) - 2, 2)]

  # Ports shared by the ALB, ECS, and the security groups
  ports = {
    http  = 80   # ALB listener
    https = 443  # VPC endpoints
    app   = 8080 # the Spring Boot app (server.port in application.properties)
    mysql = 3306 # Aurora
  }

  # Where this lab lives in the repository (CodeBuild paths and the pipeline trigger)
  lab_path = "labs/aws/01-ecs-fargate-alb-codepipeline"

  # Applied to every resource through the provider's default_tags
  common_tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
    Repository  = var.github_repository
  }
}
