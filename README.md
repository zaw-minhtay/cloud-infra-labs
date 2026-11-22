# Cloud & Infrastructure Labs

Hands-on labs, system architecture designs, and how-to notes from my work as a cloud and
infrastructure engineer. Everything here was built and run by me on real cloud accounts.

## Architectures

System designs: diagram, decisions, trade-offs, and cost.

| # | Architecture | What it covers | Related lab |
|---|---|---|---|
| | *Coming soon* | | |

## Labs

Hands-on builds, grouped by the main skill they practise.

| Category | # | Lab | What it covers | Tools |
|---|---|---|---|---|
| | | *Coming soon* | | |

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
| Terraform files | `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf` | |
| Diagram | `diagram.drawio` (source, edit in draw.io) + `diagram.png` (export) next to the README | |

Names use lowercase letters, numbers, and hyphens only.

> Labs create real cloud resources that can cost money. Always run the cleanup steps
> (for Terraform: `terraform destroy`) when you finish.
