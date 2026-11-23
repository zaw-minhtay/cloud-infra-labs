# Names and settings for the ECS cluster, task definition, and service.

locals {
  ecs = {
    cluster_name       = "${local.name_prefix}-cluster"
    service_name       = "${local.name_prefix}-service-app"
    task_family        = "${local.name_prefix}-task-app"
    container_insights = "disabled" # saves cost in a lab; enable for production metrics

    container = {
      name = "app" # buildspec/buildspec.yml writes this name into imagedefinitions.json
      port = local.ports.app
      # Placeholder until the first pipeline run; CodePipeline then owns the image.
      initial_image = "${aws_ecr_repository.app.repository_url}:initial"
    }

    cpu           = var.task_cpu
    memory        = var.task_memory
    desired_count = var.app_desired_count

    # Rolling update one task at a time (2 tasks: stop 1, start 1), so one always serves.
    deployment_minimum_healthy_percent = 50
    deployment_maximum_percent         = 100
    health_check_grace_period_seconds  = 90 # time for Spring Boot to start before ALB checks count
  }
}
