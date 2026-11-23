# Cloud & Infrastructure Labs

Hands-on labs, system architecture designs, and how-to notes from my work as a cloud and
infrastructure engineer. Everything here was built and run by me, on real cloud accounts or
on a local Kubernetes cluster.

## Architectures

System designs: diagram, decisions, trade-offs, and cost.

| # | Architecture | What it covers | Related lab |
|---|---|---|---|
| 01 | [GitOps Pipeline with GitHub Actions and Argo CD on Local Kubernetes](architectures/01-gitops-github-actions-argocd/README.md) | Pull-based GitOps: CI builds and publishes images, Argo CD deploys from Git; failure handling, security, and trade-offs | [ci-cd/01](labs/ci-cd/01-gitops-github-actions-argocd/README.md) |
| 02 | [ECS Fargate Service behind an ALB with CodePipeline](architectures/02-ecs-fargate-alb-codepipeline/README.md) | Highly available ALB + ECS Fargate (one task per AZ) with Aurora MySQL, all in private subnets with VPC endpoints (no NAT); CodePipeline + CodeBuild deploy on every push; Terraform | [aws/01](labs/aws/01-ecs-fargate-alb-codepipeline/README.md) |

## Labs

Hands-on builds, grouped by the main skill they practise.

| Category | # | Lab | What it covers | Tools |
|---|---|---|---|---|
| aws | 01 | [ECS Fargate Service behind an ALB with CodePipeline](labs/aws/01-ecs-fargate-alb-codepipeline/README.md) | Java 25 Spring Boot API on 2 Fargate tasks across 2 AZs behind an ALB, Aurora MySQL, private subnets with VPC endpoints; CodePipeline deploys on every push; task-failure, failover, and rollback tests | Terraform, ECS Fargate, ALB, Aurora MySQL, CodePipeline, CodeBuild, ECR, Java 25 |
| ci-cd | 01 | [GitOps Pipeline with GitHub Actions and Argo CD on Local Kubernetes](labs/ci-cd/01-gitops-github-actions-argocd/README.md) | Every push is tested, built for arm64 + amd64, published to GHCR, and deployed by Argo CD; self-heal and Git rollback | GitHub Actions, GHCR, Argo CD, Kubernetes (kind), Kustomize, Docker |

## Notes

*Coming soon.*

## Repository layout

```
architectures/       system designs: diagram + decisions + trade-offs
labs/
├── aws/             AWS services (VPC, IAM, S3, EC2…)
├── terraform/       infrastructure as code
├── docker/          containers
├── kubernetes/      EKS, Kubernetes
├── ci-cd/           GitHub Actions, Argo CD, pipelines
└── linux/           Linux, networking, shell
notes/               short how-to guides
templates/           starting point for every new lab or architecture
new.sh               creates a new lab or architecture from the templates
```

A category folder is created when its first lab is added.

## Starting something new

Every topic can have **an architecture** (the design: *why*) and **a lab** (the build: *how*),
linked to each other.

```bash
./new.sh arch gitops-github-actions-argocd        # → architectures/01-gitops-github-actions-argocd/
./new.sh lab ci-cd gitops-github-actions-argocd   # → labs/ci-cd/01-gitops-github-actions-argocd/
```

The script picks the next number and copies the template. Then:

1. Fill in every section of the new `README.md`, including cost and cleanup.
2. Add `diagram.png` next to it.
3. Link the architecture and lab to each other (the templates have a line for this).
4. Add a row to the tables above.

## Naming rules

| What | Rule | Example |
|---|---|---|
| Lab category | The **main skill** the lab practises; other tools go in the Tools column | `ci-cd` |
| Lab folder | `labs/<category>/NN-what-you-build` — numbers restart per category | `labs/ci-cd/01-gitops-github-actions-argocd` |
| Architecture folder | `architectures/NN-system-name` | `architectures/01-gitops-github-actions-argocd` |
| Note folder | `notes/topic-name` | `notes/ssh-agent-forwarding` |
| Lab title | `# Lab NN — Title` | `# Lab 01 — GitOps Pipeline with GitHub Actions and Argo CD on Local Kubernetes` |
| Architecture title | `# Architecture NN — Title` | `# Architecture 01 — GitOps Pipeline with GitHub Actions and Argo CD on Local Kubernetes` |
| Terraform files and AWS resource names | Chosen per lab and documented in that lab's README | [aws/01: Terraform structure](labs/aws/01-ecs-fargate-alb-codepipeline/README.md#terraform-structure) |
| Diagram | `diagram.drawio` (source, edit in draw.io) + `diagram.png` (export) next to the README | |

Names use lowercase letters, numbers, and hyphens only.

> Labs create real cloud resources that can cost money. Always run the cleanup steps
> (for Terraform: `terraform destroy`) when you finish.
