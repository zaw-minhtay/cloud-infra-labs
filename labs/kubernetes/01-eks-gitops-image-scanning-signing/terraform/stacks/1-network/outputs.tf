output "vpc_id" {
  description = "The VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnets: nodes and pods"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnets: load balancer and NAT gateway"
  value       = module.vpc.public_subnets
}

output "nat_public_ip" {
  description = "The address the cluster's outbound traffic comes from (GitHub sees this)"
  value       = module.vpc.nat_public_ips[0]
}
