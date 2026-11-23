# Part 5 — Clean up (steps 22–25)

[← Part 4](4-verify.md) · [Guide index](../SETUP.md)

Delete everything this lab created, so nothing keeps costing money or holding access.
Run from the `terraform/` folder with `AWS_PROFILE` set (step 2).

## 22. Destroy the dev environment

```bash
terraform destroy -var-file=env/dev/terraform.tfvars
```

Terraform lists everything it will delete. Check it, then type `yes`. This takes about
**10–15 minutes** (Aurora is the slowest).

Expected: `Destroy complete! Resources: 66 destroyed.` In dev, `force_destroy = true`, so the
non-empty ECR repository and artifact bucket are deleted too, and Aurora is deleted without a
final snapshot. The database password secret that RDS created is deleted with the cluster.

## 23. Delete the state bucket

Only after step 22 succeeded: the bucket holds the state Terraform needed to destroy.

```bash
cd bootstrap
terraform destroy -var-file=../env/dev/terraform.tfvars
cd ..
```

Type `yes`. Expected: the **"Value for undeclared variable"** warning again (normal), then
`Destroy complete! Resources: 4 destroyed.`

## 24. Remove the GitHub access

The connection was deleted in step 22, but the GitHub app is still installed on your account:

1. On GitHub, open your profile picture → **Settings** → **Applications** → **Installed GitHub Apps**.
2. Next to **AWS Connector for GitHub**, click **Configure**.
3. At the bottom, click **Uninstall** and confirm.

Expected: **AWS Connector for GitHub** is no longer listed.

## 25. Check nothing is left

```bash
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=awslab01 Key=Environment,Values=dev \
  --query "ResourceTagMappingList[].ResourceARN" --output text
```

Expected: no output. (Right after deleting, a few ARNs can still appear for some minutes while
AWS finishes; run it again later.)

Finally, put the placeholders back so your account ID never gets committed:

```bash
git checkout -- terraform/env/dev/
git status --short
```

Expected: `git status` shows no changes under `terraform/env/`.
