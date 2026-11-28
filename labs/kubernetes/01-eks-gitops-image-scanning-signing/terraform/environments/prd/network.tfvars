# prd: bigger nodes, protected from deletion. Its own AWS account.
# For terraform/stacks/1-network.

env                  = "prd"
vpc_cidr             = "10.2.0.0/16"
public_subnet_cidrs  = ["10.2.0.0/24", "10.2.1.0/24"]
private_subnet_cidrs = ["10.2.16.0/20", "10.2.32.0/20"]
