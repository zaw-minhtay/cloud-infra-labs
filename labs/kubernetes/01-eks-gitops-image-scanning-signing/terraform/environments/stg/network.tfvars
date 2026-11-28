# stg: same shape as prd, smaller and destroyable. Its own AWS account.
# For terraform/stacks/1-network.

env                  = "stg"
vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.0.0/24", "10.1.1.0/24"]
private_subnet_cidrs = ["10.1.16.0/20", "10.1.32.0/20"]
