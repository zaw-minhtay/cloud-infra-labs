# Icons

Official icons used in this repo's diagrams, downloaded unmodified from each project's own
source. Reuse these instead of icons from third-party icon sites.

| File | Source | License / terms |
|---|---|---|
| `github-*.svg` | [primer/octicons](https://github.com/primer/octicons) (GitHub's icon set) | MIT |
| `kubernetes.svg` | [kubernetes/kubernetes](https://github.com/kubernetes/kubernetes/tree/master/logo) `logo/logo.svg` | Apache-2.0; the Kubernetes logo is a trademark of The Linux Foundation |
| `k8s-*.svg` | [kubernetes/community](https://github.com/kubernetes/community/tree/master/icons) `icons/svg/resources/labeled/` | Apache-2.0 or CC-BY-4.0 |
| `argo.svg` | [cncf/artwork](https://github.com/cncf/artwork/tree/main/projects/argo) `projects/argo/icon/color/` | [CNCF brand guidelines](https://www.cncf.io/brand-guidelines/) |
| `gatekeeper.svg` | [open-policy-agent/gatekeeper](https://github.com/open-policy-agent/gatekeeper/tree/v3.23.1/website/static/img) `website/static/img/logo.svg` (v3.23.1) | Apache-2.0 (the repository's license); Gatekeeper is part of OPA, a CNCF project: [CNCF brand guidelines](https://www.cncf.io/brand-guidelines/) |
| `ratify.svg` | [notaryproject/ratify](https://github.com/notaryproject/ratify/tree/v1.4.8) `logo.svg` (v1.4.8) | Apache-2.0 (the repository's license); Ratify is part of the Notary Project, a CNCF project: [CNCF brand guidelines](https://www.cncf.io/brand-guidelines/) |
| `aws-signer.svg` | [AWS Architecture Icons](https://aws.amazon.com/architecture/icons/) "Icon package" (2026-07-31 release), `Arch_Security-Identity/64/Arch_AWS-Signer_64.svg` | AWS allows customers to use these icons to create architecture diagrams |

**AWS icons** are not stored here: use draw.io's built-in **AWS** shape library
(`mxgraph.aws4.*`), which draws the official
[AWS Architecture Icons](https://aws.amazon.com/architecture/icons/) and their group
styles (AWS Cloud, Region, VPC, subnets). The exception is an icon the draw.io library doesn't
have yet (`aws-signer.svg`): take it unmodified from AWS's official icon package and list it
above.

Logos are used only to identify the tools in architecture diagrams, not to imply
endorsement.

## Adding an icon

1. Download it from the project's official repo or brand page.
2. Save it here with a clear name (`<project>-<thing>.svg`).
3. Add a row to the table above.
4. In draw.io, insert it with **Arrange → Insert → Image** (or drag the SVG onto the canvas).
