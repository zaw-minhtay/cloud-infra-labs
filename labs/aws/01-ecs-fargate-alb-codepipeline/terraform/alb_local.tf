# Names and settings for the Application Load Balancer.

locals {
  alb = {
    name                = "${local.name_prefix}-alb" # ALB names: max 32 characters
    listener_port       = local.ports.http
    deletion_protection = var.deletion_protection

    target_group = {
      name                 = "${local.name_prefix}-tg-app" # max 32 characters
      port                 = local.ports.app
      deregistration_delay = 30 # seconds to finish in-flight requests before a task stops

      # /healthz never touches the database, so an Aurora failover can't take every task out
      health_check = {
        path                = "/healthz"
        matcher             = "200"
        interval            = 15
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 3
      }
    }
  }
}
