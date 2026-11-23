# VPC with three subnet tiers in two AZs. Only the public tier has a route to the internet.

resource "aws_vpc" "main" {
  cidr_block           = local.vpc.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # needed for the interface endpoints' private DNS names

  tags = { Name = local.vpc.name }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = local.igw.name }
}

# All six subnets (public, app, db × 2 AZs)
resource "aws_subnet" "main" {
  for_each = local.subnets

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  tags = { Name = each.value.name }
}

# "public" has a default route to the internet gateway. "private" (app and DB subnets) only has
# the local VPC route and the S3 gateway endpoint route, so nothing there can reach the internet.
resource "aws_route_table" "main" {
  for_each = local.route_tables

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = each.value.internet_route ? [1] : []
    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.main.id
    }
  }

  tags = { Name = each.value.name }
}

resource "aws_route_table_association" "main" {
  for_each = local.subnets

  subnet_id      = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.main[each.value.route_table].id
}
