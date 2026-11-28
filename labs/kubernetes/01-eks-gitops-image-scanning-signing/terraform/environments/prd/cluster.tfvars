# prd: bigger nodes, protected from deletion. Its own AWS account.
# For terraform/stacks/2-cluster. Your IP address comes from TF_VAR_admin_cidrs, never a file.

env                 = "prd"
kubernetes_version  = "1.36"
node_instance_types = ["t3.large"]
node_min_size       = 3
node_max_size       = 6
node_desired_size   = 3
