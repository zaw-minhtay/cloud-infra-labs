# Architectures

System designs: each one explains **what** was designed, **why** each choice was made, and
**what it costs**. When a design is also built, it links to its lab in [labs/](../labs/).

Create a new design with `./new.sh arch <name>` from the repo root. It numbers designs in
order, `NN-system-name`, and starts from
[templates/ARCHITECTURE_TEMPLATE.md](../templates/ARCHITECTURE_TEMPLATE.md).

```
architectures/
├── 01-gitops-github-actions-argocd/
├── 02-ecs-fargate-alb-codepipeline/
└── 03-eks-gitops-image-scanning-signing/
    ├── README.md
    ├── diagram.drawio        draw.io source: one page per diagram
    ├── diagram.png           page 1 (the overall design)
    └── diagram-cicd.png      page 2, when there is one (here: the CI/CD flow)
```
