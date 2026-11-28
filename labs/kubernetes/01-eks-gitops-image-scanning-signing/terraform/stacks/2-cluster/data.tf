# Made by the network stack. Found by name and tag, so this stack doesn't read another stack's state.
data "aws_vpc" "this" {
  tags = {
    Name = local.name
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  tags = {
    Tier = "private"
  }
}
