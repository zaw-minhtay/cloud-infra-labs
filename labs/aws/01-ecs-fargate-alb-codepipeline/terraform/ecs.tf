# ECS cluster, task definition, and service (2 Fargate tasks across both AZs).

resource "aws_ecs_cluster" "main" {
  name = local.ecs.cluster_name

  setting {
    name  = "containerInsights"
    value = local.ecs.container_insights
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = local.ecs.task_family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = local.ecs.cpu
  memory                   = local.ecs.memory
  execution_role_arn       = aws_iam_role.main["ecs_task_execution"].arn
  task_role_arn            = aws_iam_role.main["ecs_task"].arn

  # Writable /tmp for the JVM and Tomcat; the rest of the container file system is read-only.
  volume {
    name = "tmp"
  }

  container_definitions = jsonencode([{
    name                   = local.ecs.container.name
    image                  = local.ecs.container.initial_image
    essential              = true
    readonlyRootFilesystem = true

    portMappings = [{ containerPort = local.ecs.container.port, protocol = "tcp" }]
    mountPoints  = [{ sourceVolume = "tmp", containerPath = "/tmp", readOnly = false }]

    environment = [
      { name = "DB_HOST", value = aws_rds_cluster.main.endpoint }, # writer endpoint, follows failover
      { name = "DB_NAME", value = aws_rds_cluster.main.database_name },
      { name = "DB_USER", value = aws_rds_cluster.main.master_username },
    ]

    # Injected at start-up from the RDS-managed secret; never stored in Terraform or the image.
    secrets = [
      { name = "DB_PASSWORD", valueFrom = "${aws_rds_cluster.main.master_user_secret[0].secret_arn}:password::" },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.main["app"].name
        awslogs-region        = var.region
        awslogs-stream-prefix = local.ecs.container.name
      }
    }
  }])
}

resource "aws_ecs_service" "app" {
  name            = local.ecs.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = local.ecs.desired_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = local.ecs.deployment_minimum_healthy_percent
  deployment_maximum_percent         = local.ecs.deployment_maximum_percent
  health_check_grace_period_seconds  = local.ecs.health_check_grace_period_seconds

  # Stop a failing deployment and roll back to the last working task definition.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = local.subnet_ids.app # one per AZ; ECS spreads the tasks across them
    security_groups  = [aws_security_group.main["app"].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = local.ecs.container.name
    container_port   = local.ecs.container.port
  }

  depends_on = [aws_lb_listener.http]

  lifecycle {
    # CodePipeline registers a new task definition revision on every deploy.
    # Without this, the next terraform apply would roll the service back to the old image.
    ignore_changes = [task_definition]
  }
}
