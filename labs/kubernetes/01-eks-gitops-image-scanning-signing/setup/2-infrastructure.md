# Part 2 — Infrastructure (steps 9–13)

[← Part 1](1-prepare.md) · [Guide index](../SETUP.md) · Next: [Part 3 — Release →](3-release.md)

Build the AWS side with Terraform, one stack at a time, each with its own state:
**bootstrap** (the state bucket) → **network** → **cluster** → **platform**. See the
[README](../README.md#terraform-structure) for why it is split this way.

> ⚠️ **From step 10 on, this lab costs money** (about $0.33 per hour). Finish the same day with
> [Part 5 — Clean up](5-clean-up.md).

## 9. Set your values

Terraform reads two personal values from environment variables, so they are never written in a
file: your GitHub username (for the workflows' trust policy and Argo CD's repository address)
and your IP address (the only address the Kubernetes API accepts from the internet). The state
bucket's name contains your account ID, read from your login.

```bash
cd ~/k8slab01/cloud-infra-labs/labs/kubernetes/01-eks-gitops-image-scanning-signing/terraform
export AWS_PROFILE=<your-dev-profile>
export GITHUB_OWNER=<your-github-username>
export TF_VAR_github_owner="$GITHUB_OWNER"
export TF_VAR_admin_cidrs="[\"$(curl -s https://checkip.amazonaws.com)/32\"]"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export STATE_BUCKET="k8slab01-dev-tfstate-${ACCOUNT_ID}-ap-northeast-1"
echo "$TF_VAR_admin_cidrs $TF_VAR_github_owner"
```

Expected: your IP address as a list, e.g. `["203.0.113.10/32"]`, then your GitHub username.

**In a new terminal, run this step again** before any `terraform` or `kubectl` command. If your
IP address changes (another network), run it again and re-apply step 12 so `kubectl` can still
reach the cluster.

## 10. Create the state bucket

The [bootstrap](../terraform/bootstrap/main.tf) creates the S3 bucket that holds the other
stacks' state: versioned, encrypted, private, and HTTPS only. The bootstrap itself keeps its small
state on your machine (`terraform.tfstate`, ignored by git), because the bucket doesn't exist yet.

```bash
cd bootstrap
terraform init
terraform apply -var-file=../environments/dev/bootstrap.tfvars
```

Type `yes` when asked. Expected: `Apply complete!` and

```
state_bucket = "k8slab01-dev-tfstate-<account-id>-ap-northeast-1"
```

the same name as `$STATE_BUCKET`.

**Via console:** **S3** → **General purpose buckets** → `k8slab01-dev-tfstate-…` → **Properties**.
Expected: **Bucket Versioning: Enabled**, default encryption SSE-S3.

**Via CLI:**

```bash
aws s3api get-bucket-versioning --bucket "$STATE_BUCKET" --query Status --output text
```

Expected: `Enabled`.

## 11. Build the network

The [network stack](../terraform/stacks/1-network/main.tf) creates the VPC across two
Availability Zones: public subnets (load balancer, NAT gateway), large private subnets (nodes and
pod IPs), one NAT gateway, and free gateway endpoints for S3 and DynamoDB
([dev values](../terraform/environments/dev/network.tfvars)).

```bash
cd ../stacks/1-network
terraform init -backend-config="bucket=$STATE_BUCKET" -backend-config="key=dev/network.tfstate"
terraform apply -var-file=../../environments/dev/network.tfvars
```

Type `yes`. Takes about 3 minutes. Expected: `Apply complete!` and the outputs `vpc_id`,
`private_subnet_ids` (two), `public_subnet_ids` (two), and `nat_public_ip`.

**Via console:** **VPC** → **Subnets**, filter by the VPC `k8slab01-dev`. Expected four subnets:
`k8slab01-dev-public-1a`, `k8slab01-dev-public-1c`, `k8slab01-dev-private-1a`,
`k8slab01-dev-private-1c`.

**Via CLI:**

```bash
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)" \
  --query "Subnets[].[Tags[?Key=='Name']|[0].Value, CidrBlock]" --output text | sort
```

Expected:

```
k8slab01-dev-private-1a	10.0.16.0/20
k8slab01-dev-private-1c	10.0.32.0/20
k8slab01-dev-public-1a	10.0.0.0/24
k8slab01-dev-public-1c	10.0.1.0/24
```

## 12. Build the EKS cluster

The [cluster stack](../terraform/stacks/2-cluster/main.tf) creates the EKS cluster
`k8slab01-dev` (Kubernetes 1.36, secrets encrypted with KMS, API reachable from the internet only
from your IP), its add-ons (VPC CNI with network policies, CoreDNS, kube-proxy, Pod Identity
Agent, EBS CSI driver), and a managed node group of two `t3.medium` nodes in the private subnets
([dev values](../terraform/environments/dev/cluster.tfvars)). It finds the VPC by its name tag,
so it doesn't read the network stack's state.

```bash
cd ../2-cluster
terraform init -backend-config="bucket=$STATE_BUCKET" -backend-config="key=dev/cluster.tfstate"
terraform apply -var-file=../../environments/dev/cluster.tfvars
```

Type `yes`. Takes about 15–20 minutes. Expected: `Apply complete!` and the outputs
`cluster_name = "k8slab01-dev"`, `cluster_version = "1.36"`, `cluster_endpoint`, and
`oidc_provider_arn`.

Connect `kubectl` to the cluster (it gets a short-lived token from your AWS login each time):

```bash
aws eks update-kubeconfig --name k8slab01-dev --region ap-northeast-1
kubectl get nodes -L topology.kubernetes.io/zone
```

Expected: two nodes, both `Ready`, one in `ap-northeast-1a` and one in `ap-northeast-1c`.

**Via console:** **EKS** → **Clusters** → `k8slab01-dev`. Expected: **Status: Active**,
**Kubernetes version: 1.36**; **Compute** tab → node group `k8slab01-dev-default` with 2 nodes.
(If the console says your IAM principal has no access, you are signed in to the console as a
different identity from your CLI profile: see [troubleshooting](troubleshooting.md).)

## 13. Build the platform

The [platform stack](../terraform/stacks/3-platform/main.tf) creates everything that runs on
the cluster or serves it:

- **Image pipeline** ([module](../terraform/modules/image-pipeline/main.tf)): ECR repositories
  `k8slab01-dev/candidate/sample-web-app` (every build) and
  `k8slab01-dev/release/sample-web-app` (released versions, immutable tags), Amazon Inspector
  scanning for ECR, an AWS Signer signing profile, and ECR managed signing for `release`.
- **GitHub access to AWS** ([module](../terraform/modules/github-oidc/main.tf)): GitHub's OIDC
  provider and two roles, `k8slab01-dev-github-ci` and `k8slab01-dev-github-release`.
- **The app's data:** the DynamoDB table `k8slab01-dev-items`, and EKS Pod Identity roles for the
  app and the AWS Load Balancer Controller.
- **Admission control** ([module](../terraform/modules/admission-control/main.tf)): OPA
  Gatekeeper and Ratify (Helm), with Ratify trusting only your Signer profile.
- **Argo CD** ([module](../terraform/modules/argocd-bootstrap/main.tf)): installed once, your
  cluster registered with its per-account values as annotations, and the root Application
  pointing at your `eks-platform-gitops`. From then on, Argo CD installs the rest from Git.

```bash
cd ../3-platform
terraform init -backend-config="bucket=$STATE_BUCKET" -backend-config="key=dev/platform.tfstate"
terraform apply -var-file=../../environments/dev/platform.tfvars
```

Type `yes`. Takes about 5–10 minutes. Expected: `Apply complete!` and these outputs:

```
argocd_namespace        = "argocd"
candidate_repository    = "k8slab01-dev/candidate/sample-web-app"
ecr_registry            = "<account-id>.dkr.ecr.ap-northeast-1.amazonaws.com"
github_ci_role_arn      = "arn:aws:iam::<account-id>:role/k8slab01-dev-github-ci"
github_release_role_arn = "arn:aws:iam::<account-id>:role/k8slab01-dev-github-release"
items_table             = "k8slab01-dev-items"
release_repository      = "k8slab01-dev/release/sample-web-app"
signing_profile_arn     = "arn:aws:signer:ap-northeast-1:<account-id>:/signing-profiles/k8slab01_dev_release_…"
```

If your account already turned on Amazon Inspector scanning for ECR, this stack takes it over,
and step 26 turns it off again: see [troubleshooting](troubleshooting.md).

**Check admission control is running:**

```bash
kubectl -n gatekeeper-system get pods
```

Expected: `gatekeeper-audit-…` (1), `gatekeeper-controller-manager-…` (2), and `ratify-…` (1),
all `Running`.

**Check Argo CD.** Within 2–3 minutes it reads your GitOps repository and creates one
Application per namespace.

**Via browser (the Argo CD UI):** in a second terminal (with step 9's `export` lines run):

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Open https://localhost:8080 (accept the self-signed certificate warning), sign in as `admin`
with the printed password. Leave the port-forward running while you use the UI; `Ctrl+C` stops it.

**Via CLI:**

```bash
kubectl -n argocd get applications
```

Expected:

| Application | Sync | Health |
|---|---|---|
| `root` | Synced | Healthy |
| `argocd` | Synced | Healthy |
| `gatekeeper` | Synced | Healthy |
| `platform` | Synced | Healthy |
| `sample-web-app` | Synced | **Progressing**, later **Degraded** |

`sample-web-app` is not healthy yet, **on purpose**: nothing has been released, so its overlay
has no image version or digest, and Gatekeeper refuses its pods. You can see why:

```bash
kubectl -n app-dev get events --field-selector reason=FailedCreate -o custom-columns=MESSAGE:.message | head -3
```

Expected: messages starting with `admission webhook "validation.gatekeeper.sh" denied the
request`, then each broken rule in brackets, for example `[images-pinned-by-digest]`. Nothing
runs until a scanned and signed release exists: that is Part 3.

Next: [Part 3 — Release →](3-release.md)
