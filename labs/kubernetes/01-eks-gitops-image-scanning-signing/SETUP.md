# Step-by-step guide — Lab 01 GitOps Platform on EKS with Image Scanning and Signing

Everything from a fresh machine to a working EKS platform where only scanned and signed images
run, in order. For what this lab is and why, see the [overview](README.md).

This guide is long, so it is split into parts. Step numbers continue from one part to the next.

> ⚠️ **Status:** written but not yet run end-to-end on AWS and GitHub. Checked so far: the app
> builds and its 12 tests pass (step 6), the workflows parse and their scripts pass a syntax
> check, the Kustomize manifests build, and every Terraform stack passes `terraform validate`.
> This note is removed once every step has been run and its output checked.

| Part | Steps | What you'll do |
|---|---|---|
| [1. Prepare](setup/1-prepare.md) | 1–8 | Install the tools, connect to AWS and GitHub, create your two repositories, and set up the GitHub App ($0) |
| [2. Infrastructure](setup/2-infrastructure.md) | 9–13 | Build the state bucket, network, EKS cluster, and platform with Terraform; Argo CD starts syncing |
| [3. Release](setup/3-release.md) | 14–18 | Connect the workflows to AWS, build, release `v1.0.0`, watch Argo CD deploy it, use the app |
| [4. Verify](setup/4-verify.md) | 19–24 | Prove the guardrails: a scan stops a release, the cluster refuses unsigned images and unsafe pods, a lost pod, self-heal, rollback |
| [5. Clean up](setup/5-clean-up.md) | 25–32 | Delete the load balancer first, then every stack, the state bucket, the GitHub App, and local settings |
| [Troubleshooting](setup/troubleshooting.md) | — | Common errors and how to fix them |

> ⚠️ **This lab costs money.** Parts 2–4 run real AWS resources: about **$0.33 per hour
> (~$8–9 per day)**, mostly the EKS control plane, two nodes, and the NAT gateway, plus about $1
> of Inspector scans. Do parts 2–5 on the same day and finish with
> [Clean up](setup/5-clean-up.md).

**Console first, then CLI.** Where a step can be done or checked in the AWS console, in GitHub,
or in the Argo CD web UI, the guide shows **Via console** (or **Via browser**) first, then
**Via CLI**: use either one. Terraform, git, and `kubectl` have no console, so those steps are
CLI only.

Written for **macOS** with Homebrew. Written against Terraform 1.17.1, AWS provider 6.74,
AWS CLI 2.39, and EKS Kubernetes 1.36.

**Placeholders and names used in this guide:**

| Placeholder | Means |
|---|---|
| `<your-github-username>` | Your own GitHub username (step 3 stores it in `$GITHUB_OWNER`) |
| `<your-dev-profile>` | The AWS CLI profile for your **dev** AWS account |
| `<app_url>` | The app's address: `http://` + the load balancer's DNS name (step 18) |

The three repositories, kept side by side in one folder, `~/k8slab01`:

| Repository | Where it comes from | Holds |
|---|---|---|
| `cloud-infra-labs` | Cloned from [zaw-minhtay/cloud-infra-labs](https://github.com/zaw-minhtay/cloud-infra-labs) | This guide and the Terraform |
| `sample-web-app` | **Your own copy**, made from the template [zaw-minhtay/sample-web-app](https://github.com/zaw-minhtay/sample-web-app) | The app and its CI and release workflows |
| `eks-platform-gitops` | **Your own copy**, made from the template [zaw-minhtay/eks-platform-gitops](https://github.com/zaw-minhtay/eks-platform-gitops) | What Argo CD deploys |

## What you need

| Tool / account | Used for | Install from (official) |
|---|---|---|
| An AWS account for **dev** | Where everything is created. Use a lab/dev account, not production, with permission to create VPC, EKS, IAM, ECR, Inspector, Signer, and DynamoDB resources (e.g. administrator). | [aws.amazon.com](https://aws.amazon.com/) — step 2 |
| AWS CLI v2 | Talks to AWS from the terminal; also gives `kubectl` its login token | [docs.aws.amazon.com](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) — step 1 |
| Terraform 1.17 or later | Creates all AWS resources and installs Argo CD, Gatekeeper, and Ratify | [developer.hashicorp.com](https://developer.hashicorp.com/terraform/install) — step 1 |
| kubectl | Looks at and tests the cluster | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/) — step 1 |
| GitHub CLI (`gh`) | Creates your repositories, sets workflow settings, watches workflow runs | [cli.github.com](https://cli.github.com/) — step 1 |
| git | Commits and tags | Apple Command Line Tools — step 1 |
| A GitHub account | Hosts your two repositories; runs the workflows (free for public repositories) | [github.com/signup](https://github.com/signup) — step 3 |
| Docker Desktop (optional) | Builds the app on your machine before AWS (step 6) | [docs.docker.com](https://docs.docker.com/desktop/setup/install/mac-install/) |

You do **not** need Java or Maven: the image build (with the tests) runs inside Docker, on your
machine and in GitHub Actions.

Start with [Part 1 — Prepare](setup/1-prepare.md).
