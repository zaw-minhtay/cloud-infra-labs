# Cloud & Infrastructure Labs

Hands-on labs, system architecture designs, and how-to notes from my work as a cloud and
infrastructure engineer. Everything here was built and run by me on real cloud accounts.

**Portfolio:** [zawminhtay.com](https://zawminhtay.com)

## Labs

| # | Lab | What it covers | Tools |
|---|---|---|---|
| | *Coming soon* | | |

## Architectures

| # | Architecture | What it covers |
|---|---|---|
| | *Coming soon* | |

## Notes

*Coming soon.*

## Repository layout

```
labs/            hands-on labs, numbered in the order I built them
architectures/   system designs: diagram + decisions + trade-offs
notes/           short how-to guides
templates/       starting point for every new lab or architecture
```

## Naming rules

| What | Rule | Example |
|---|---|---|
| Lab folder | `labs/NN-what-you-build` — next number, lowercase, hyphens | `labs/01-eks-cluster` |
| Architecture folder | `architectures/NN-system-name` | `architectures/01-three-tier-web-app` |
| Note folder | `notes/topic-name` | `notes/ssh-agent-forwarding` |
| Lab title (first line of README) | `# Lab NN — Title` | `# Lab 01 — EKS Cluster with Terraform` |
| Terraform files | `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf` | |
| Diagram | `diagram.png` next to the README | |

## Adding a new lab

1. Create `labs/NN-what-you-build/` using the next number.
2. Copy [templates/LAB_TEMPLATE.md](templates/LAB_TEMPLATE.md) into it as `README.md`.
3. Fill in every section, including cost and cleanup.
4. Add a row to the **Labs** table above.

New architectures work the same way with
[templates/ARCHITECTURE_TEMPLATE.md](templates/ARCHITECTURE_TEMPLATE.md).

> Labs create real cloud resources that can cost money. Always run the cleanup steps
> (for Terraform: `terraform destroy`) when you finish.
