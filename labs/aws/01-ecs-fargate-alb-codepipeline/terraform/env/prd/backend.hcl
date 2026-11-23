# Terraform state for prd, in the prd account's state bucket (created by ../../bootstrap).
bucket       = "awslab01-prd-s3-tfstate-REPLACE_WITH_PRD_ACCOUNT_ID-ap-northeast-1"
key          = "labs/aws/01-ecs-fargate-alb-codepipeline/prd/terraform.tfstate"
region       = "ap-northeast-1"
encrypt      = true
use_lockfile = true
