# Part 5 — Clean up (steps 22–25)

[← Part 4](4-verify.md) · [Guide index](../SETUP.md)

Delete everything this lab created, so nothing keeps costing money or holding access.
Run the CLI commands from the `terraform/` folder with `AWS_PROFILE` set (step 2).

## 22. Destroy the dev environment

Terraform created everything, so Terraform deletes it (CLI only):

```bash
terraform destroy -var-file=env/dev/terraform.tfvars
```

Terraform lists everything it will delete. Check it, then type `yes`. This takes about
**10–15 minutes** (Aurora is the slowest).

Expected: `Destroy complete! Resources: 67 destroyed.` In dev, `force_destroy = true`, so the
non-empty ECR repository and artifact bucket are deleted too, and Aurora is deleted without a
final snapshot. The database password secret that RDS created is deleted with the cluster.

Check the main pieces are gone:

**Via console:**
- **ECS** → **Clusters**: no `awslab01-dev-cluster`.
- **RDS** → **Databases**: no `awslab01-dev-aurora`.
- **EC2** → **Load Balancers**: no `awslab01-dev-alb`.

**Via CLI:** the `Destroy complete!` line above.

## 23. Delete the state bucket

Only after step 22 succeeded: the bucket holds the state Terraform needed to destroy. CLI only:

```bash
cd bootstrap
terraform destroy -var-file=../env/dev/terraform.tfvars
cd ..
```

Type `yes`. Expected: the **"Value for undeclared variable"** warning again (normal), then
`Destroy complete! Resources: 5 destroyed.`

Check:

**Via console:** **S3** → **General purpose buckets**. Expected: no
`awslab01-dev-s3-tfstate-…` bucket.

**Via CLI:** the `Destroy complete!` line above.

## 24. Remove the GitHub access

The connection was deleted in step 22, but the GitHub app is still installed on your account.
This is done on the GitHub website:

1. On GitHub, open your profile picture → **Settings** → **Applications** → **Installed GitHub Apps**.
2. Next to **AWS Connector for GitHub**, click **Configure**.
3. At the bottom, click **Uninstall** and confirm.

Expected: **AWS Connector for GitHub** is no longer listed.

## 25. Check nothing is left

**Via console:** **Resource Groups & Tag Editor** → **Tag Editor**. Choose region
**ap-northeast-1**, resource types **All supported resource types**, and the tags
`Project` = `awslab01` and `Environment` = `dev`, then **Search resources**. Expected: no
resources found.

**Via CLI:**

```bash
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=awslab01 Key=Environment,Values=dev \
  --query "ResourceTagMappingList[].ResourceARN" --output text
```

Expected: no output.

Right after deleting, a few resources can still appear for some minutes while AWS finishes;
check again later.

Finally, put the GitHub placeholder back so your username never gets committed (git, CLI only):

```bash
git checkout -- env/dev/
git status --short env/
```

Expected: `git status` shows no changes under `env/`.
