# Application Load Balancer: the public entry point. Spreads traffic across healthy tasks in both AZs.

resource "aws_lb" "main" {
  name                       = local.alb.name
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = [aws_security_group.main["alb"].id]
  subnets                    = local.subnet_ids.public
  drop_invalid_header_fields = true
  enable_deletion_protection = local.alb.deletion_protection
}

resource "aws_lb_target_group" "app" {
  name                 = local.alb.target_group.name
  port                 = local.alb.target_group.port
  protocol             = "HTTP"
  target_type          = "ip" # Fargate tasks register by IP
  vpc_id               = aws_vpc.main.id
  deregistration_delay = local.alb.target_group.deregistration_delay

  health_check {
    path                = local.alb.target_group.health_check.path
    matcher             = local.alb.target_group.health_check.matcher
    interval            = local.alb.target_group.health_check.interval
    timeout             = local.alb.target_group.health_check.timeout
    healthy_threshold   = local.alb.target_group.health_check.healthy_threshold
    unhealthy_threshold = local.alb.target_group.health_check.unhealthy_threshold
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = local.alb.listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
