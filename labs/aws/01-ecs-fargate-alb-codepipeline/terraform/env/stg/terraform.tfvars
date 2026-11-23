# stg: same shape as prd, but smaller and destroyable. Lives in its own AWS account.
# Replace the two placeholders before deploying stg.

env        = "stg"
account_id = "REPLACE_WITH_STG_ACCOUNT_ID" # your stg AWS account (12 digits)

vpc_cidr            = "10.1.0.0/16"
public_subnet_cidrs = ["10.1.0.0/24", "10.1.1.0/24"]
app_subnet_cidrs    = ["10.1.10.0/24", "10.1.11.0/24"]
db_subnet_cidrs     = ["10.1.20.0/24", "10.1.21.0/24"]

github_repository = "your-github-username/cloud-infra-labs"
github_branch     = "release/stg"

app_desired_count = 2
task_cpu          = 512
task_memory       = 1024

db_instance_class        = "db.t4g.medium"
db_backup_retention_days = 7

deletion_protection = false
log_retention_days  = 14
force_destroy       = true
