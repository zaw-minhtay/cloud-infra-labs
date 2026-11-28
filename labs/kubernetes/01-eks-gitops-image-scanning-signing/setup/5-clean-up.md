# Part 5 — Clean up (steps 25–32)

[← Part 4](4-verify.md) · [Guide index](../SETUP.md)

Delete everything the lab created, so nothing keeps costing money or holding access. Run step 9's
`export` lines first if this is a new terminal.

**The order matters.** The load balancer was created by a controller in the cluster, not by
Terraform, so Terraform doesn't know about it. Delete it first, while the controller still has
its AWS permissions; otherwise it is left behind and the VPC can't be deleted. Then destroy the
stacks in the reverse order of building them: platform → cluster → network → state bucket.

## 25. Delete the load balancer

First stop Argo CD from putting things back (it would recreate the Ingress within seconds), then
delete the Ingress. The AWS Load Balancer Controller then deletes the load balancer and its
security groups; `kubectl delete` waits until it has.

```bash
kubectl -n argocd scale statefulset argocd-application-controller --replicas=0
kubectl -n app-dev delete ingress sample-web-app
```

Expected: `statefulset.apps/argocd-application-controller scaled`, then (after up to a minute)
`ingress.networking.k8s.io "sample-web-app" deleted`.

**Via console:** **EC2** → **Load Balancers**. Expected: no load balancer whose name starts with
`k8s-appdev-` (reload after a minute if it is still being deleted).

**Via CLI:**

```bash
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?starts_with(LoadBalancerName, 'k8s-appdev')].LoadBalancerName" --output text
```

Expected: no output.

## 26. Destroy the platform

Deletes Argo CD, Gatekeeper and Ratify, the ECR repositories with their images, the DynamoDB
table, the IAM roles, and GitHub's OIDC provider (if this lab created it); turns off Inspector
scanning for ECR; and
cancels the Signer profile.

```bash
cd ~/k8slab01/cloud-infra-labs/labs/kubernetes/01-eks-gitops-image-scanning-signing/terraform/stacks/3-platform
terraform destroy -var-file=../../environments/dev/platform.tfvars
```

Type `yes`. Takes about 5 minutes. Expected: `Destroy complete!`.

AWS Signer doesn't delete signing profiles: the profile stays in the list as **Canceled**, can't
sign anything, and costs nothing.

## 27. Destroy the cluster

Deletes the node group, the EKS cluster and its add-ons, and schedules the cluster's KMS key for
deletion.

```bash
cd ../2-cluster
terraform destroy -var-file=../../environments/dev/cluster.tfvars
```

Type `yes`. Takes about 10–15 minutes. Expected: `Destroy complete!`.

**Via console:** **EKS** → **Clusters**. Expected: no `k8slab01-dev`.

## 28. Destroy the network

Deletes the NAT gateway (and its public IP address), the gateway endpoints, the subnets, and the
VPC.

```bash
cd ../1-network
terraform destroy -var-file=../../environments/dev/network.tfvars
```

Type `yes`. Takes about 2–3 minutes. Expected: `Destroy complete!`. If deleting the VPC or a
subnet times out with a `DependencyViolation`, something created outside Terraform is still in
it, usually the load balancer: see [troubleshooting](troubleshooting.md).

## 29. Delete the state bucket

The stacks are gone, so their state isn't needed. In dev, `force_destroy = true`
([bootstrap.tfvars](../terraform/environments/dev/bootstrap.tfvars)), so Terraform also deletes
every old version of the state files.

```bash
cd ../../bootstrap
terraform destroy -var-file=../environments/dev/bootstrap.tfvars
rm -f terraform.tfstate terraform.tfstate.backup
```

Type `yes`. Expected: `Destroy complete!`.

**Via CLI:**

```bash
aws s3api head-bucket --bucket "$STATE_BUCKET"
```

Expected: an error with `Not Found` (404): the bucket is gone.

## 30. Remove the GitHub access

The GitHub App's private key is stored in `sample-web-app`; delete the App so that key is worth
nothing.

**Via browser:** GitHub → your profile picture → **Settings** → **Developer settings** →
**GitHub Apps** → `<your-github-username>-gitops-release` → **Advanced** → **Delete GitHub App**,
and confirm by typing its name.

Then delete the workflow settings (the AWS roles they point to no longer exist).

**Via browser:** `sample-web-app` → **Settings** → **Secrets and variables** → **Actions**:
delete the three variables and the secret.

**Via CLI:**

```bash
for v in AWS_CI_ROLE_ARN AWS_RELEASE_ROLE_ARN GITOPS_APP_CLIENT_ID; do gh variable delete "$v" --repo "$GITHUB_OWNER/sample-web-app"; done
gh secret delete GITOPS_APP_PRIVATE_KEY --repo "$GITHUB_OWNER/sample-web-app"
gh variable list --repo "$GITHUB_OWNER/sample-web-app"; gh secret list --repo "$GITHUB_OWNER/sample-web-app"
```

Expected: the last two commands print nothing.

You can keep your two repositories (they hold nothing secret) or delete them: **Settings** →
**Danger Zone** → **Delete this repository**. From the CLI, `gh repo delete` needs an extra
permission first: `gh auth refresh -s delete_repo`, then
`gh repo delete "$GITHUB_OWNER/sample-web-app"` (it asks you to type the name to confirm).

## 31. Remove the cluster from your kubectl settings

`aws eks update-kubeconfig` (step 12) added the cluster, a user, and a context, all named after
the cluster's ARN:

```bash
for c in $(kubectl config get-contexts -o name | grep 'cluster/k8slab01-dev$'); do
  kubectl config delete-context "$c"; kubectl config delete-cluster "$c"; kubectl config delete-user "$c"
done
kubectl config get-contexts -o name | grep k8slab01 || echo "removed"
```

Expected: three `deleted …` lines, then `removed`.

If you built the app on your machine (step 6): `docker rmi sample-web-app:local`.

## 32. Check nothing is left

Every AWS resource Terraform created carries the tag `Project=k8slab01`, and the load balancer
got the same tag from the Ingress.

**Via console:** **Resource Groups & Tag Editor** → **Tag Editor** → Regions:
`ap-northeast-1`, Resource types: **All supported resource types**, Tag key `Project`, value
`k8slab01` → **Search resources**.

**Via CLI:**

```bash
aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=k8slab01 \
  --query "ResourceTagMappingList[].ResourceARN" --output text
```

Expected: nothing, except at most:
- the cluster's KMS key (`…:key/…`), now **Pending deletion**: AWS deletes it after its waiting
  period, and a key pending deletion costs nothing;
- the Signer profile (`…:/signing-profiles/…`), **Canceled** (step 26).

The tag list can lag a few minutes behind deletions; if something else appears, wait and run it
again.

Finally, check Inspector no longer scans ECR in this account (unless you use it for other work):

```bash
aws inspector2 batch-get-account-status --query "accounts[0].resourceState.ecr.status" --output text
```

Expected: `DISABLED`.
