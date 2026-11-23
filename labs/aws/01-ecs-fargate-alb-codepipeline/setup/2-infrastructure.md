# Part 2 — Infrastructure (steps 6–10)

[← Part 1](1-prepare.md) · [Guide index](../SETUP.md) · Next: [Part 3 — Pipeline →](3-pipeline.md)

Fill in your values, create the Terraform state bucket, and build the whole environment.
⚠️ **From step 7 on, resources cost money** (~$10/day). Finish with [Part 5](5-clean-up.md) the same day.

Terraform files are in [terraform/](../terraform/): one `<service>.tf` (resources) and one
`<service>_local.tf` (names and settings) per AWS service, and `env/<env>/` per environment.
See the [overview](../README.md#terraform-structure) for how they fit together.

## 6. Fill in your values for dev

Two files hold the dev-specific values:
[env/dev/terraform.tfvars](../terraform/env/dev/terraform.tfvars) and
[env/dev/backend.hcl](../terraform/env/dev/backend.hcl). Replace their placeholders with your
account ID and GitHub repository:

```bash
cd terraform
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
GITHUB_USER=<your-github-username>
sed -i '' -e "s/REPLACE_WITH_DEV_ACCOUNT_ID/$ACCOUNT_ID/" \
  -e "s#your-github-username/cloud-infra-labs#$GITHUB_USER/cloud-infra-labs#" \
  env/dev/terraform.tfvars env/dev/backend.hcl
grep -n "REPLACE_WITH\|your-github-username" env/dev/* || echo "all placeholders replaced"
```

Expected: `all placeholders replaced`.

> Don't commit these two files with your account ID. In step 15 you'll stage only the app file.

## 7. Create the state bucket (bootstrap)

Terraform stores what it created in a **state file**. It goes in an S3 bucket in the same
account: versioned, encrypted, and private. [bootstrap/](../terraform/bootstrap/) creates that
bucket, once per account:

```bash
cd bootstrap
terraform init
terraform apply -var-file=../env/dev/terraform.tfvars
```

Terraform shows the plan and asks **Do you want to perform these actions?** — check it, then
type `yes`.

Expected:
- A warning **"Value for undeclared variable"**: normal. The bootstrap only uses a few of the
  values in that file.
- `Apply complete! Resources: 5 added, 0 changed, 0 destroyed.`
- `state_bucket = "awslab01-dev-s3-tfstate-<account-id>-ap-northeast-1"`: the same name as
  `bucket` in `env/dev/backend.hcl`.

The bootstrap keeps its own small state file locally (`bootstrap/terraform.tfstate`, git-ignored).
Keep it until [step 23](5-clean-up.md#23-delete-the-state-bucket).

## 8. Connect Terraform to the state bucket

```bash
cd ..
terraform init -backend-config=env/dev/backend.hcl
```

Expected: `Successfully configured the backend "s3"!` and `Terraform has been successfully initialized!`

## 9. Review the plan

The first apply starts the ECS service with **0 tasks**: the ECR repository is still empty, so
tasks would have no image to run. The pipeline builds the first image in Part 3, then you start
the 2 tasks.

```bash
terraform plan -var-file=env/dev/terraform.tfvars -var app_desired_count=0
```

Expected: `Plan: 67 to add, 0 to change, 0 to destroy.` Scroll through it: every name follows
the naming rule `awslab01-dev-…`.

## 10. Build the environment

```bash
terraform apply -var-file=env/dev/terraform.tfvars -var app_desired_count=0
```

Type `yes` when asked. This takes **about 15–20 minutes**; Aurora is the slowest part.

Expected: `Apply complete! Resources: 67 added, 0 changed, 0 destroyed.` and the outputs:

```
app_url                   = "http://awslab01-dev-alb-….ap-northeast-1.elb.amazonaws.com"
aurora_cluster_identifier = "awslab01-dev-aurora"
aurora_reader_identifier  = "awslab01-dev-aurora-1c"
aurora_writer_identifier  = "awslab01-dev-aurora-1a"
codeconnection_name       = "awslab01-dev-github"
ecr_repository_url        = "<account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/awslab01-dev-app"
ecs_cluster_name          = "awslab01-dev-cluster"
ecs_service_name          = "awslab01-dev-service-app"
pipeline_name             = "awslab01-dev-pipeline"
```

The pipeline also starts once by itself when it is created. That first run **fails at Source**,
because the GitHub connection isn't finished yet. You'll fix that in step 11.

Next: [Part 3 — Pipeline →](3-pipeline.md)
