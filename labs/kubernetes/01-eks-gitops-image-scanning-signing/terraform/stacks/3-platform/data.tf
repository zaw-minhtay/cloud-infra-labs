# Made by the network and cluster stacks. Found by name, so this stack doesn't read their state.
data "aws_eks_cluster" "this" {
  name = local.name
}

data "aws_vpc" "this" {
  tags = {
    Name = local.name
  }
}

data "aws_iam_openid_connect_provider" "cluster" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}
