# Labs

Hands-on labs, grouped by the **main skill** they practise. Other tools a lab uses are listed
in its README, not in the folder name.

| Category | For labs mainly about |
|---|---|
| `aws/` | AWS services (VPC, IAM, S3, EC2…) |
| `terraform/` | Infrastructure as code |
| `docker/` | Containers |
| `kubernetes/` | EKS and Kubernetes itself (nodes, networking, Helm, autoscaling) |
| `ci-cd/` | Pipelines: GitHub Actions, Argo CD, GitOps |
| `linux/` | Linux, networking, shell |

Create a new lab with `./new.sh lab <category> <name>` from the repo root. It numbers labs
per category, `NN-what-you-build`, and starts from
[templates/LAB_TEMPLATE.md](../templates/LAB_TEMPLATE.md).

```
labs/
└── ci-cd/
    └── 01-gitops-github-actions-argocd/
        ├── README.md
        └── diagram.png
```
