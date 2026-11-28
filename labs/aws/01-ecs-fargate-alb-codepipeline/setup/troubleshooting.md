# Troubleshooting

[← Guide index](../SETUP.md)

Run the commands from the `terraform/` folder with `AWS_PROFILE` set.

## Terraform

| Problem | Cause | Fix |
|---|---|---|
| `Set github_repository to your own owner/name` | The GitHub placeholder is still in `env/dev/terraform.tfvars` | Run step 6 again |
| `Value for undeclared variable "account_id"` | Your `terraform.tfvars` is from an older version of this lab, which had an `account_id` line | Delete that line: the account now comes from your AWS login |
| `No valid credential sources found` / `ExpiredToken` | Not signed in, or the session expired | Sign in again (step 2) |
| `terraform init`: `S3 bucket ... does not exist` | You're logged in to a different account than the one with the state bucket, or the bucket wasn't created | `aws sts get-caller-identity`: if it's the wrong account, `export AWS_PROFILE=<your-dev-profile>`; otherwise run step 7. Compare `state_bucket` from step 7 with the bucket name in step 8 |
| `Error acquiring the state lock` | An earlier run was interrupted | Wait for other runs to finish; then `terraform force-unlock <lock-id>` with the ID from the error |

## Pipeline

| Problem | Cause | Fix |
|---|---|---|
| **Source** fails: connection not available | The GitHub connection is still `PENDING` | Step 11 |
| **Source** fails: repository not found | The GitHub app can't see your repo, or `github_repository` is wrong | Step 11 (choose `cloud-infra-labs`); check `env/dev/terraform.tfvars` |
| **Build** fails | A test failed, or the image didn't build | Read the build log: `aws logs tail /aws/codebuild/awslab01-dev-build --since 30m` |
| **Deploy** fails | New tasks didn't become healthy | See "ECS tasks" below; the circuit breaker has already rolled back |
| A push doesn't start the pipeline | The change wasn't under `app/` or `terraform/buildspec/`, or not on `main` | Expected: only those paths trigger it. Start it by hand: `aws codepipeline start-pipeline-execution --name awslab01-dev-pipeline` |

## ECS tasks

First look at the service events and the app logs:

```bash
aws ecs describe-services --cluster awslab01-dev-cluster --services awslab01-dev-service-app \
  --query "services[0].events[0:5].message" --output text
aws logs tail /ecs/awslab01-dev/app --since 15m
```

| Problem | Cause | Fix |
|---|---|---|
| `CannotPullContainerError` | The task can't reach ECR: endpoint or security group issue | Check the `awslab01-dev-vpce-ecr-*` endpoints are `available` and the S3 gateway endpoint exists |
| `ResourceInitializationError` … secrets | The task can't read the DB password | Check the `awslab01-dev-vpce-secretsmanager` endpoint; the execution role must be `awslab01-dev-role-ecs-task-execution` |
| Tasks start, then the ALB marks them unhealthy | The app didn't start, or listens on the wrong port | Read the app logs; it must log `Tomcat started on port 8080` |
| Tasks keep restarting right after deploy | Spring Boot needs more time to start | The grace period is 90 seconds (`ecs_local.tf`); raise it if your account is slower |
| Desired count is 0 after step 10 | Expected: the first apply uses `app_desired_count=0` | Step 13 |

## The API

| Problem | Cause | Fix |
|---|---|---|
| `{"error":"storage unavailable, try again"}` for more than a minute | The app can't reach Aurora | Check the cluster is `available`: `aws rds describe-db-clusters --db-cluster-identifier awslab01-dev-aurora --query "DBClusters[0].Status"`; the DB security group must allow `awslab01-dev-sg-app` |
| `curl` hangs or `Connection refused` | No healthy task yet | Step 13: wait for `healthy healthy` |
| `502 Bad Gateway` right after a deploy | A task was being replaced | Retry after a few seconds |

## Clean up

| Problem | Cause | Fix |
|---|---|---|
| `terraform destroy` fails on the ECR repository or S3 bucket | `force_destroy` is `false` (stg/prd settings) | In dev it is `true`; for other envs empty them first |
| `terraform destroy` fails on Aurora or the ALB: deletion protection | `deletion_protection = true` (prd) | Expected for prd; set it to `false`, apply, then destroy |
| Step 25 still lists resources | AWS is still finishing the deletions | Wait a few minutes and run it again |
