# dev: lowest cost, everything can be destroyed. Deployed by this lab (setup/2-infrastructure.md).
# Replace the two placeholders before the first `terraform plan`.

env        = "dev"
account_id = "REPLACE_WITH_DEV_ACCOUNT_ID" # your dev AWS account (12 digits)

vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.0.0/24", "10.0.1.0/24"]
app_subnet_cidrs    = ["10.0.10.0/24", "10.0.11.0/24"]
db_subnet_cidrs     = ["10.0.20.0/24", "10.0.21.0/24"]

github_repository = "your-github-username/cloud-infra-labs"
github_branch     = "main"

app_desired_count = 2 # one task per AZ
task_cpu          = 512
task_memory       = 1024

db_instance_class        = "db.t4g.medium"
db_backup_retention_days = 1

deletion_protection = false
log_retention_days  = 7
force_destroy       = true
