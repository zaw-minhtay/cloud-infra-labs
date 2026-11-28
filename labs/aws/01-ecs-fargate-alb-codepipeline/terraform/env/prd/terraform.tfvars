# prd: bigger tasks and database, longer backups and logs, protected from deletion.
# Lives in its own AWS account. Replace the GitHub placeholder before deploying prd. The AWS
# account comes from your AWS login (the prd profile), so no account ID is written here.

env = "prd"

vpc_cidr            = "10.2.0.0/16"
public_subnet_cidrs = ["10.2.0.0/24", "10.2.1.0/24"]
app_subnet_cidrs    = ["10.2.10.0/24", "10.2.11.0/24"]
db_subnet_cidrs     = ["10.2.20.0/24", "10.2.21.0/24"]

github_repository = "your-github-username/cloud-infra-labs"
github_branch     = "release/prd"

app_desired_count = 2
task_cpu          = 1024
task_memory       = 2048

db_instance_class        = "db.r7g.large"
db_backup_retention_days = 14

deletion_protection = true # ALB and Aurora can't be deleted by accident
log_retention_days  = 30
force_destroy       = false # keep a final DB snapshot; never delete non-empty buckets
