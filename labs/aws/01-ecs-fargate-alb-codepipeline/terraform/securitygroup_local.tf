# Names and settings for the security groups (one per tier) and their rules.

locals {
  security_groups = {
    alb = {
      name        = "${local.name_prefix}-sg-alb"
      description = "ALB: HTTP from the internet"
    }
    app = {
      name        = "${local.name_prefix}-sg-app"
      description = "ECS tasks: app port from the ALB only"
    }
    db = {
      name        = "${local.name_prefix}-sg-db"
      description = "Aurora: MySQL from the ECS tasks only"
    }
    vpce = {
      name        = "${local.name_prefix}-sg-vpce"
      description = "VPC endpoints: HTTPS from inside the VPC"
    }
  }

  ports = {
    http  = 80
    https = 443
    app   = 8080
    mysql = 3306
  }

  # Each tier only accepts traffic from the tier in front of it:
  #   internet -> ALB :80 -> tasks :8080 -> Aurora :3306;  tasks -> VPC endpoints :443
  #
  # sg          = the security group the rule belongs to
  # direction   = "ingress" or "egress"
  # the other side is exactly one of: cidr, peer_sg (a key above), or s3_endpoint = true
  security_group_rules = {
    alb-in-http-from-internet = {
      sg          = "alb"
      direction   = "ingress"
      port        = local.ports.http
      cidr        = "0.0.0.0/0"
      peer_sg     = null
      s3_endpoint = false
      description = "HTTP from the internet"
    }
    alb-out-to-app = {
      sg          = "alb"
      direction   = "egress"
      port        = local.ports.app
      cidr        = null
      peer_sg     = "app"
      s3_endpoint = false
      description = "To the ECS tasks"
    }
    app-in-from-alb = {
      sg          = "app"
      direction   = "ingress"
      port        = local.ports.app
      cidr        = null
      peer_sg     = "alb"
      s3_endpoint = false
      description = "From the ALB only"
    }
    app-out-to-db = {
      sg          = "app"
      direction   = "egress"
      port        = local.ports.mysql
      cidr        = null
      peer_sg     = "db"
      s3_endpoint = false
      description = "To Aurora"
    }
    app-out-to-endpoints = {
      sg          = "app"
      direction   = "egress"
      port        = local.ports.https
      cidr        = null
      peer_sg     = "vpce"
      s3_endpoint = false
      description = "To the interface endpoints (ECR, Secrets Manager, Logs)"
    }
    app-out-to-s3 = {
      sg          = "app"
      direction   = "egress"
      port        = local.ports.https
      cidr        = null
      peer_sg     = null
      s3_endpoint = true
      description = "To S3 through the gateway endpoint (ECR image layers)"
    }
    db-in-from-app = {
      sg          = "db"
      direction   = "ingress"
      port        = local.ports.mysql
      cidr        = null
      peer_sg     = "app"
      s3_endpoint = false
      description = "From the ECS tasks only"
    }
    vpce-in-https-from-vpc = {
      sg          = "vpce"
      direction   = "ingress"
      port        = local.ports.https
      cidr        = var.vpc_cidr
      peer_sg     = null
      s3_endpoint = false
      description = "HTTPS from inside the VPC"
    }
  }
}
