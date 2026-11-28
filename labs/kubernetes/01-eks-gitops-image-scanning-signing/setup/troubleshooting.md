# Troubleshooting

[← Guide index](../SETUP.md)

Common errors, grouped by where they appear. Most come from a missing setting or a new terminal
without step 9's `export` lines: check those first.

## Terraform

| Problem | Cause | Fix |
|---|---|---|
| `terraform init`: `NoSuchBucket` or `S3 bucket ... does not exist` | `$STATE_BUCKET` is empty (new terminal), the bootstrap (step 10) wasn't run, or you are logged in to another AWS account | Run step 9 again and check `aws sts get-caller-identity` shows the dev account; then run step 10 if the bucket doesn't exist |
| Platform apply: `EntityAlreadyExists: Provider with url https://token.actions.githubusercontent.com already exists` | Your account already has GitHub's OIDC provider (an account can have only one) | `export TF_VAR_create_github_oidc_provider=false` and apply again. Keep it set for `terraform destroy` too, so the existing provider is left alone |
| Your account already used **Amazon Inspector for ECR** or its own ECR scanning rules | The platform stack turns Inspector on for ECR and sets the registry's scanning rules; destroying it (step 26) turns Inspector for ECR off | Before step 13, note your settings with `aws ecr get-registry-scanning-configuration`. After step 26, restore them and run `aws inspector2 enable --resource-types ECR` |
| Any stack: `Error: ... cluster ... not found` or `no matching VPC found` | A stack that comes earlier wasn't applied, or was applied in another account | Apply the stacks in order: network → cluster → platform |
| Platform apply or destroy hangs, then `Kubernetes cluster unreachable` or `i/o timeout` | Your IP address changed, so the cluster's public endpoint refuses you | Run step 9 again (it reads your current IP), `terraform apply` the cluster stack (step 12), then retry |

## kubectl and the EKS console

| Problem | Cause | Fix |
|---|---|---|
| `Unable to connect to the server: dial tcp ...: i/o timeout` | Your IP address changed (another network) | Run step 9 again and re-apply the cluster stack (step 12) |
| `You must be logged in to the server (Unauthorized)` or `the server has asked for the client to provide credentials` | `AWS_PROFILE` is a different identity from the one that created the cluster (only that one is an administrator) | `export AWS_PROFILE=<your-dev-profile>` (the one used in step 12) and check with `aws sts get-caller-identity` |
| EKS console: **Your current IAM principal doesn't have access to Kubernetes objects on this cluster** | You are signed in to the console as a different IAM identity from your CLI profile | Use the CLI commands, or give the console identity access: `aws eks create-access-entry --cluster-name k8slab01-dev --principal-arn <console-role-arn>`, then `aws eks associate-access-policy --cluster-name k8slab01-dev --principal-arn <console-role-arn> --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy --access-scope type=cluster`. It is deleted with the cluster |
| `kubectl -n argocd port-forward ...`: `address already in use` | Something else uses port 8080 | Use another local port: `kubectl -n argocd port-forward svc/argocd-server 8081:443` and open https://localhost:8081 |

## GitHub workflows

| Problem | Cause | Fix |
|---|---|---|
| `gh run watch` shows an older run | The new run hadn't started when `gh run list` ran | `gh run list --workflow <ci.yml or release.yml> --limit 3` and pass the newest run's ID to `gh run watch --exit-status` |
| **ci** or **release** fails at **Get AWS credentials (OIDC)**: `Not authorized to perform sts:AssumeRoleWithWebIdentity`, or `Credentials could not be loaded` | The role ARN variable is missing or wrong (step 14), your repository's owner or name differs from what Terraform trusts (`TF_VAR_github_owner`, `sample-web-app`), or **release** ran from something other than a `v*` tag | Check `gh variable list --repo "$GITHUB_OWNER/sample-web-app"`; if the owner was wrong, fix step 9 and re-apply the platform stack; then **Re-run jobs** on the failed run |
| **release**: `No image for commit ... in k8slab01-dev/candidate/sample-web-app` | The tagged commit wasn't built by CI, or its CI run hadn't finished | Wait for the commit's **ci** run to pass, then open the failed release run → **Re-run jobs** |
| **release** stops with `… critical vulnerabilities. Nothing is released.` on a version you didn't mean to break | A new critical CVE was published for the base image or a library since the lab was written | See which package it is (the command in step 19, point 3, with your commit ID); update that version in `pom.xml` or the `Dockerfile`, push, and tag the **next** version |
| **release**: `The scan can't be used: …` (`UNSUPPORTED_IMAGE`, `SCAN_ELIGIBILITY_EXPIRED`, …) | Inspector couldn't scan the image, or it is older than Inspector's rescan window | Push a new commit so CI builds and scans a fresh image, then tag that commit |
| **release** fails at **Get a GitHub App token** | The App isn't installed on `eks-platform-gitops`, or the Client ID or private key is wrong | Repeat step 8: check the installation (**Settings** → **Applications** → **Installed GitHub Apps**), the variable, and the secret; then re-run the job |
| **release** fails at **Open the pull request and merge it**: `the base branch policy prohibits the merge` | Branch protection wants a review for the changed file: CODEOWNERS lost the no-owner line for `overlays/dev`, or **Required approvals** is above 0 | Check step 7's settings. The pull request stays open: merge it yourself (Argo CD then deploys it), and future releases merge on their own |
| **release** fails at the pull request step: `Resource not accessible by integration` | The App lacks **Contents** or **Pull requests** write permission | Fix the App's permissions (step 8). When you change them, accept the new permissions on the installation: **Settings** → **Applications** → the App → **Review request** |

## Argo CD and the app

| Problem | Cause | Fix |
|---|---|---|
| `root` shows `ComparisonError`, `repository not found`, or no other Applications appear | Argo CD can't read your GitOps repository: it is private, or its owner or name isn't what Terraform used | Make `eks-platform-gitops` public (step 5), check `TF_VAR_github_owner`, and re-apply the platform stack |
| `sample-web-app` is **Degraded** before the first release | Expected: there is no released image yet, so Gatekeeper refuses the pods (step 13) | Release a version (Part 3) |
| After a release, pods are refused with `[signed-by-our-signer-profile]` | Ratify couldn't verify the signature: the AWS Signer plugin didn't load, or Ratify can't read ECR | `kubectl -n gatekeeper-system logs deploy/ratify --tail=50` shows the reason. Check the plugin's status with `kubectl describe verifier aws-signer-plugin`, and that Ratify's service account has the role annotation: `kubectl -n gatekeeper-system get sa ratify-admin -o yaml` |
| Pods are refused with `System error calling external data provider` | Gatekeeper can't reach Ratify, or Ratify's TLS certificate isn't ready yet | `kubectl -n gatekeeper-system get pods`: wait until `ratify-…` is `Running`, or restart it with `kubectl -n gatekeeper-system rollout restart deploy/ratify`. Argo CD retries the sync by itself |
| The page says `storage unavailable, try again` | The pod can't reach DynamoDB: Pod Identity credentials or the table | `kubectl -n app-dev logs deploy/sample-web-app --tail=30` shows the AWS error. Check the association exists: `aws eks list-pod-identity-associations --cluster-name k8slab01-dev --namespace app-dev` |
| `<app_url>` doesn't answer | A new load balancer takes 2–3 minutes, or the controller couldn't create it | `kubectl -n app-dev describe ingress sample-web-app` shows the controller's events; its log: `kubectl -n platform logs deploy/aws-load-balancer-controller --tail=50` |

## Clean up

| Problem | Cause | Fix |
|---|---|---|
| Network destroy: `DependencyViolation` on a subnet, internet gateway, or the VPC | The load balancer (or its security groups) still exists, because step 25 was skipped or failed | **EC2** → **Load Balancers**: delete the one starting with `k8s-appdev-`; **Target Groups**: delete those starting with `k8s-`; **Security Groups** (filter by the VPC): delete those starting with `k8s-`. Then run step 28 again |
| `kubectl delete ingress` waits for a long time | The controller is deleting the load balancer, or it lost its permissions (the platform was destroyed first) | Wait up to 2 minutes. If the platform is already gone, delete the load balancer in the console as in the row above, then remove the finalizer: `kubectl -n app-dev patch ingress sample-web-app --type=merge -p '{"metadata":{"finalizers":null}}'` |
| Bootstrap destroy: `BucketNotEmpty` | `force_destroy` was false when the bucket was created | `terraform apply -var-file=../environments/dev/bootstrap.tfvars -var force_destroy=true`, then destroy again |
