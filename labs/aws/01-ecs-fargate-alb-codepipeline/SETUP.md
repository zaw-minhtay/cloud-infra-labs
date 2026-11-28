# Step-by-step guide — Lab 01 ECS Fargate Service behind an ALB with CodePipeline

Everything from a fresh machine to a working, highly available deployment on AWS, in order.
For what this lab is and why, see the [overview](README.md).

This guide is long, so it is split into parts. Step numbers continue from one part to the next.

> ⚠️ **Status:** Part 1 has been run and checked (the app builds, its tests pass, and it works
> against MySQL 8.0). Parts 2–5 are written and the Terraform passes `terraform validate`, but
> they have not been run end-to-end on AWS yet. This note is removed once every step has been
> run and its output checked.

| Part | Steps | What you'll do |
|---|---|---|
| [1. Prepare](setup/1-prepare.md) | 1–5 | Install the tools, connect to your AWS account, and run the app on your machine ($0) |
| [2. Infrastructure](setup/2-infrastructure.md) | 6–10 | Fill in your values, create the state bucket, and build everything with Terraform |
| [3. Pipeline](setup/3-pipeline.md) | 11–15 | Connect GitHub, run the pipeline, start the tasks, use the app, deploy a change |
| [4. Verify](setup/4-verify.md) | 16–21 | Prove HA and safety: two AZs, no internet route, task failure, Aurora failover, rollback, alarms |
| [5. Clean up](setup/5-clean-up.md) | 22–27 | Delete everything, including the task definitions, the state bucket, and the GitHub access; put your repo back |
| [Troubleshooting](setup/troubleshooting.md) | — | Common errors and how to fix them |

> ⚠️ **This lab costs money.** Parts 2–4 run real AWS resources: about **$0.43 per hour
> (~$10 per day)**, mostly Aurora and the VPC endpoints. Do parts 2–5 on the same day and finish
> with [Clean up](setup/5-clean-up.md).

**Console first, then CLI.** Where a step can be done or checked in the AWS console (or the
browser), the guide shows **Via console** first, then **Via CLI**: use either one. Terraform, git,
and Docker have no console, so those steps are CLI only.

Written for **macOS** with the AWS CLI and Terraform. Tested with Terraform 1.17.1, AWS
provider 6.73, AWS CLI 2.39, and Docker 29.9.

**Placeholders used in this guide:**

| Placeholder | Means |
|---|---|
| `<your-github-username>` | Your own GitHub username |
| `<your-dev-profile>` | The AWS CLI profile for your **dev** AWS account |
| `<app_url>` | The app's address: `http://` + the ALB's DNS name (step 14) |

## What you need

| Tool / account | Used for | Install from (official) |
|---|---|---|
| An AWS account for **dev** | Where everything is created. Use a lab/dev account, not production, with permission to create VPC, IAM, ECS, RDS, and CodePipeline resources (e.g. administrator). | [aws.amazon.com](https://aws.amazon.com/) — step 2 |
| AWS CLI v2 | Talks to AWS from the terminal | [docs.aws.amazon.com](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) — step 1 |
| Terraform 1.17 or later | Creates all AWS resources | [developer.hashicorp.com](https://developer.hashicorp.com/terraform/install) — step 1 |
| git | Gets your copy of the repo, pushes changes | Apple Command Line Tools — step 1 |
| A GitHub account | Hosts your copy of the repo; CodePipeline reads it | [github.com/signup](https://github.com/signup) — step 3 |
| Docker Desktop (optional) | Runs the app on your machine before AWS (steps 4–5) | [docs.docker.com](https://docs.docker.com/desktop/setup/install/mac-install/) |

You do **not** need Java or Maven on your machine: the image build (with the tests) runs inside
Docker, both on your machine and in CodeBuild.

Start with [Part 1 — Prepare](setup/1-prepare.md).
