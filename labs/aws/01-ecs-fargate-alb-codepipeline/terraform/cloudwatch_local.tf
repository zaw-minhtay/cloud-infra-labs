# Names and settings for the log groups and the alarms.

locals {
  log_groups = {
    # ECS task (container) logs
    app = {
      name = "/ecs/${local.name_prefix}/app"
    }
    # CodeBuild logs
    build = {
      name = "/aws/codebuild/${local.name_prefix}-build"
    }
  }

  # A separate local from the log group name on purpose: the alarms refer to the ECS service,
  # and the service refers to the log group, so one shared local would create a dependency loop.
  # Each alarm checks one signal every `period` seconds and fires after
  # `evaluation_periods` bad periods in a row.
  alarms = {
    alb-5xx = {
      description        = "The app returns server errors (5xx) through the ALB"
      namespace          = "AWS/ApplicationELB"
      metric             = "HTTPCode_Target_5XX_Count"
      statistic          = "Sum"
      threshold          = 5
      period             = 300
      evaluation_periods = 1
      dimensions = {
        LoadBalancer = aws_lb.main.arn_suffix
        TargetGroup  = aws_lb_target_group.app.arn_suffix
      }
    }
    alb-unhealthy-hosts = {
      description        = "At least one task fails the ALB health check"
      namespace          = "AWS/ApplicationELB"
      metric             = "UnHealthyHostCount"
      statistic          = "Maximum"
      threshold          = 1
      period             = 60
      evaluation_periods = 3
      dimensions = {
        LoadBalancer = aws_lb.main.arn_suffix
        TargetGroup  = aws_lb_target_group.app.arn_suffix
      }
    }
    ecs-cpu-high = {
      description        = "The tasks use more than 80% CPU"
      namespace          = "AWS/ECS"
      metric             = "CPUUtilization"
      statistic          = "Average"
      threshold          = 80
      period             = 300
      evaluation_periods = 2
      dimensions = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.app.name
      }
    }
    aurora-cpu-high = {
      description        = "Aurora uses more than 80% CPU"
      namespace          = "AWS/RDS"
      metric             = "CPUUtilization"
      statistic          = "Average"
      threshold          = 80
      period             = 300
      evaluation_periods = 2
      dimensions = {
        DBClusterIdentifier = aws_rds_cluster.main.cluster_identifier
      }
    }
    aurora-connections-high = {
      description        = "Aurora has an unusually high number of connections"
      namespace          = "AWS/RDS"
      metric             = "DatabaseConnections"
      statistic          = "Maximum"
      threshold          = 60
      period             = 300
      evaluation_periods = 2
      dimensions = {
        DBClusterIdentifier = aws_rds_cluster.main.cluster_identifier
      }
    }
  }
}
