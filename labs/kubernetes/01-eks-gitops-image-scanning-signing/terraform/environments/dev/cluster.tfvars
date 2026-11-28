# dev: lowest cost, everything can be destroyed. The only environment this lab deploys.
# For terraform/stacks/2-cluster. Your IP address comes from TF_VAR_admin_cidrs, never a file.

env                 = "dev"
kubernetes_version  = "1.36"
node_instance_types = ["t3.medium"]
node_min_size       = 2
node_max_size       = 3
node_desired_size   = 2
