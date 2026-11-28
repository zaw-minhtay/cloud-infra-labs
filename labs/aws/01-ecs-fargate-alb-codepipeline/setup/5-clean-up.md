# Part 5 — Clean up (steps 22–27)

[← Part 4](4-verify.md) · [Guide index](../SETUP.md)

Delete everything this lab created, so nothing keeps costing money or holding access, and put
your repository back the way it started. Run the CLI commands from the `terraform/` folder with
`AWS_PROFILE` set (step 2).

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

## 23. Delete the task definitions

Every pipeline run registers a new **task definition revision** (`awslab01-dev-task-app:2`,
`:3`, …). Terraform only knows revision 1, so `destroy` leaves the others. They cost nothing,
but they are still left in your account. Deleting one takes two actions: **deregister** it
(it becomes inactive), then **delete** it.

**Via console:** **ECS** → **Task definitions** → **awslab01-dev-task-app**.
1. Select every **Active** revision → **Actions** → **Deregister**, and confirm.
2. Show the **Inactive** revisions, select all of them → **Actions** → **Delete**, and confirm.

**Via CLI:**

```bash
for td in $(aws ecs list-task-definitions --family-prefix awslab01-dev-task-app --status ACTIVE --query "taskDefinitionArns[]" --output text); do
  aws ecs deregister-task-definition --task-definition "$td" --query "taskDefinition.revision" --output text
done
aws ecs delete-task-definitions --query "failures[].reason" --output text \
  --task-definitions $(aws ecs list-task-definitions --family-prefix awslab01-dev-task-app --status INACTIVE --query "taskDefinitionArns[]" --output text)
```

Expected: the loop prints the revision numbers it deregistered (`2`, `3`, …), and the delete
prints nothing (no failures).

Check:

**Via console:** **ECS** → **Task definitions**. Expected: no `awslab01-dev-task-app` (or no
revisions left in it).

**Via CLI:**

```bash
aws ecs list-task-definitions --family-prefix awslab01-dev-task-app --output text
```

Expected: no output.

## 24. Delete the state bucket

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

## 25. Remove the GitHub access

The connection was deleted in step 22, but the GitHub app is still installed on your account.
This is done on the GitHub website:

1. On GitHub, open your profile picture → **Settings** → **Applications** → **Installed GitHub Apps**.
2. Next to **AWS Connector for GitHub**, click **Configure**.
3. At the bottom, click **Uninstall** and confirm.

Expected: **AWS Connector for GitHub** is no longer listed.

## 26. Check nothing is left

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

This search reads AWS's tag index, which updates later than the resources themselves. Right
after deleting, resources that are already gone (VPC endpoints, security group rules, the ECS
cluster) can still be listed for a while; check again later.

## 27. Put your repository back

Step 15 pushed `items-api-v2` to your `main`, and your local `terraform.tfvars` holds your
GitHub username. Put both back, so the next run of the lab starts the same way (git, CLI only):

```bash
cd ..
sed -i '' 's/"app", "items-api-v2"/"app", "items-api"/' app/src/main/java/com/example/items/ItemController.java
git add app/src/main/java/com/example/items/ItemController.java
git commit -m "chore(aws): put the app name back after the lab"
git push
git checkout -- terraform/env/dev/
git status --short
cd terraform
```

The pipeline was deleted in step 22, so this push doesn't deploy anything.

Expected: `git status` shows no changes (nothing under `app/` or `terraform/env/`).
