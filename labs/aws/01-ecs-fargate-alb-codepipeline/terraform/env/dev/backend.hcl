# Terraform state for dev, in the dev account's state bucket (created by ../../bootstrap).
# Replace the placeholder with your dev account ID.
bucket       = "awslab01-dev-s3-tfstate-REPLACE_WITH_DEV_ACCOUNT_ID-ap-northeast-1"
key          = "labs/aws/01-ecs-fargate-alb-codepipeline/dev/terraform.tfstate"
region       = "ap-northeast-1"
encrypt      = true
use_lockfile = true
