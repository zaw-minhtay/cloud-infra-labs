# Terraform state for prd, in the prd account's state bucket (created by ../../bootstrap).
# `bucket` is not set here: its name contains the account ID, so `terraform init` passes it,
# reading the ID from your AWS login. A backend file can't use variables or locals.
key          = "labs/aws/01-ecs-fargate-alb-codepipeline/prd/terraform.tfstate"
region       = "ap-northeast-1"
encrypt      = true
use_lockfile = true
