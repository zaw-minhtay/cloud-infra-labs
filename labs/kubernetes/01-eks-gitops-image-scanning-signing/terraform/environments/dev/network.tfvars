# dev: lowest cost, everything can be destroyed. The only environment this lab deploys.
# For terraform/stacks/1-network.

env                  = "dev"
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnet_cidrs = ["10.0.16.0/20", "10.0.32.0/20"]
