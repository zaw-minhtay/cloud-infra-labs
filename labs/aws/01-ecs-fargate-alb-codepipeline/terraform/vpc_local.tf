# Names and settings for the VPC, subnets, internet gateway, and route tables.

locals {
  vpc = {
    name = "${local.name_prefix}-vpc"
    cidr = var.vpc_cidr
  }

  igw = {
    name = "${local.name_prefix}-igw"
  }

  # Three tiers, one subnet per AZ in each: public (ALB), app (ECS tasks), db (Aurora).
  # Keys look like "public-1a", "app-1c", "db-1a".
  subnet_tiers = {
    public = {
      cidrs       = var.public_subnet_cidrs
      route_table = "public"
    }
    app = {
      cidrs       = var.app_subnet_cidrs
      route_table = "private"
    }
    db = {
      cidrs       = var.db_subnet_cidrs
      route_table = "private"
    }
  }

  subnets = merge([
    for tier, settings in local.subnet_tiers : {
      for i, az in var.azs : "${tier}-${local.az_suffix[i]}" => {
        tier        = tier
        az          = az
        cidr        = settings.cidrs[i]
        route_table = settings.route_table
        name        = "${local.name_prefix}-subnet-${tier}-${local.az_suffix[i]}"
      }
    }
  ]...)

  route_tables = {
    # Default route to the internet gateway
    public = {
      name           = "${local.name_prefix}-rtb-public"
      internet_route = true
    }
    # No internet route, on purpose
    private = {
      name           = "${local.name_prefix}-rtb-private"
      internet_route = false
    }
  }
}

# Subnet IDs per tier, in AZ order (e.g. local.subnet_ids.app = [app-1a, app-1c]).
# A separate local from the settings above because it reads the created subnets.
locals {
  subnet_ids = {
    for tier in keys(local.subnet_tiers) : tier => [
      for key, subnet in aws_subnet.main : subnet.id if local.subnets[key].tier == tier
    ]
  }
}
