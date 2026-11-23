# Terraform state for stg, in the stg account's state bucket (created by ../../bootstrap).
bucket       = "awslab01-stg-s3-tfstate-REPLACE_WITH_STG_ACCOUNT_ID-ap-northeast-1"
key          = "labs/aws/01-ecs-fargate-alb-codepipeline/stg/terraform.tfstate"
region       = "ap-northeast-1"
encrypt      = true
use_lockfile = true
