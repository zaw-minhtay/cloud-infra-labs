# VPC across 2 AZs: public subnets for the load balancer and the NAT gateway, private subnets
# for the nodes and pods (the VPC CNI gives every pod an address from its subnet).
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.9.0"

  name = local.name
  cidr = var.vpc_cidr
  azs  = var.azs

  public_subnets       = var.public_subnet_cidrs
  public_subnet_names  = [for az in local.az_suffix : "${local.name}-public-${az}"]
  private_subnets      = var.private_subnet_cidrs
  private_subnet_names = [for az in local.az_suffix : "${local.name}-private-${az}"]

  # One NAT gateway for the whole VPC: half the cost of one per AZ, but outbound access then
  # depends on AZ a. Production: one_nat_gateway_per_az = true.
  enable_nat_gateway = true
  single_nat_gateway = true

  # The AWS Load Balancer Controller finds subnets by the kubernetes.io/role tags;
  # the cluster stack finds the private subnets by Tier.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    Tier                     = "public"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    Tier                              = "private"
  }
}

# Free gateway endpoints: image layers (S3) and the app's data (DynamoDB) stay on the AWS
# network instead of going through the NAT gateway.
module "gateway_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.9.0"

  vpc_id                = module.vpc.vpc_id
  create_security_group = false

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags = {
        Name = "${local.name}-s3"
      }
    }
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags = {
        Name = "${local.name}-dynamodb"
      }
    }
  }
}
