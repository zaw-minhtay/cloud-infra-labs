# VPC endpoints: private access to ECR, S3, Secrets Manager, and CloudWatch Logs.
# Interface endpoints live in the app subnets; the S3 gateway endpoint is a route.

resource "aws_vpc_endpoint" "main" {
  for_each = local.vpc_endpoints

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.${each.value.service}"
  vpc_endpoint_type = each.value.type

  # Interface endpoints only
  subnet_ids          = each.value.type == "Interface" ? local.subnet_ids.app : null
  security_group_ids  = each.value.type == "Interface" ? [aws_security_group.main["vpce"].id] : null
  private_dns_enabled = each.value.type == "Interface" ? true : null

  # Gateway endpoints only
  route_table_ids = each.value.type == "Gateway" ? [aws_route_table.main["private"].id] : null

  tags = { Name = each.value.name }
}
