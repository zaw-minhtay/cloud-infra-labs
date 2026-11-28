# Part 2 — Infrastructure (steps 6–10)

[← Part 1](1-prepare.md) · [Guide index](../SETUP.md) · Next: [Part 3 — Pipeline →](3-pipeline.md)

Fill in your values, create the Terraform state bucket, and build the whole environment.
⚠️ **From step 7 on, resources cost money** (~$10/day). Finish with [Part 5](5-clean-up.md) the same day.

Terraform files are in [terraform/](../terraform/): one `<service>.tf` (resources) and one
`<service>_local.tf` (names and settings) per AWS service, and `env/<env>/` per environment.
See the [overview](../README.md#terraform-structure) for how they fit together.

Terraform runs only from the terminal, so the build steps are CLI only. Each check shows the
console first.

## 6. Fill in your values for dev

[env/dev/terraform.tfvars](../terraform/env/dev/terraform.tfvars) holds the dev-specific values.
The only one you change is the GitHub repository the pipeline reads.

**Via editor:** open `terraform/env/dev/terraform.tfvars`, replace `your-github-username` in
`github_repository` with your GitHub username, and save.

**Via CLI:**

```bash
cd terraform
GITHUB_USER=<your-github-username>
sed -i '' "s#your-github-username/cloud-infra-labs#$GITHUB_USER/cloud-infra-labs#" env/dev/terraform.tfvars
grep -n "your-github-username" env/dev/terraform.tfvars || echo "placeholder replaced"
```

Expected: `github_repository = "<your-github-username>/cloud-infra-labs"` in the file (the CLI
prints `placeholder replaced`).

No file holds your **AWS account ID**: Terraform reads it from your AWS login (step 2). So the
account you're logged in to is the account Terraform builds in. Check it before every Terraform
step:

**Via console:** the account menu at the top right shows the **Account ID**.

**Via CLI:**

```bash
aws sts get-caller-identity --query Account --output text
```

Expected: your **dev** account ID, the same in both.

> Don't commit `terraform.tfvars` with your GitHub username. In step 15 you'll stage only the
> app file.

## 7. Create the state bucket (bootstrap)

Terraform stores what it created in a **state file**. It goes in an S3 bucket in the same
account: versioned, encrypted, and private. [bootstrap/](../terraform/bootstrap/) creates that
bucket, once per account (CLI only):

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
- `state_bucket = "awslab01-dev-s3-tfstate-<account-id>-ap-northeast-1"`, with your dev account
  ID taken from your login. Step 8 builds the same name.

Check the bucket:

**Via console:** **S3** → **General purpose buckets**. Expected:
`awslab01-dev-s3-tfstate-<account-id>-ap-northeast-1` is listed.

**Via CLI:** the `state_bucket` output above.

The bootstrap keeps its own small state file locally (`bootstrap/terraform.tfstate`, git-ignored).
Keep it until [step 24](5-clean-up.md#24-delete-the-state-bucket).

## 8. Connect Terraform to the state bucket

[env/dev/backend.hcl](../terraform/env/dev/backend.hcl) has every backend setting except the
bucket name: the name contains the account ID, and a backend file can't use variables or
locals. So `init` gets the bucket name on the command line, with the account ID read from your
login (CLI only):

```bash
cd ..
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
terraform init -backend-config=env/dev/backend.hcl \
  -backend-config="bucket=awslab01-dev-s3-tfstate-${ACCOUNT_ID}-ap-northeast-1"
```

Expected: `Successfully configured the backend "s3"!` and `Terraform has been successfully initialized!`

If you're logged in to the wrong account, this fails with `S3 bucket ... does not exist`: that
account has no dev state bucket. This is what keeps Terraform from building in the wrong account.

## 9. Review the plan

The first apply starts the ECS service with **0 tasks**: the ECR repository is still empty, so
tasks would have no image to run. The pipeline builds the first image in Part 3, then you start
the 2 tasks. CLI only:

```bash
terraform plan -var-file=env/dev/terraform.tfvars -var app_desired_count=0
```

Expected: `Plan: 67 to add, 0 to change, 0 to destroy.` Scroll through it: every name follows
the naming rule `awslab01-dev-…`.

## 10. Build the environment

CLI only:

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

Check the main pieces exist:

**Via console:**
- **ECS** → **Clusters**: `awslab01-dev-cluster`, with the service `awslab01-dev-service-app`
  at 0 tasks.
- **RDS** → **Databases**: `awslab01-dev-aurora` with `awslab01-dev-aurora-1a` and
  `awslab01-dev-aurora-1c`, all **Available**.
- **EC2** → **Load Balancers**: `awslab01-dev-alb`, **Active**.

**Via CLI:** the outputs above.

The pipeline also starts once by itself when it is created. That first run **fails at Source**
(**CodePipeline** → **awslab01-dev-pipeline** shows Source **Failed**), because the GitHub
connection isn't finished yet. You'll fix that in step 11.

Next: [Part 3 — Pipeline →](3-pipeline.md)
