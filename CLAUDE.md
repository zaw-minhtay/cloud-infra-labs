# CLAUDE.md — Rules for AI-assisted work in this repo

Claude Code reads this file before working here. When a rule below conflicts with Claude's
default behaviour, this file wins.

This repo is a **public portfolio** of cloud and platform engineering work: architecture
designs and hands-on labs (AWS, Terraform, Kubernetes, CI/CD). Everything in it must be
something the owner actually designed, built, and ran.

---

## 1. Hard rules

- **Never commit secrets.** No access keys, tokens, passwords, private keys, kubeconfigs,
  or `.env` files. Use placeholders (`<your-account-id>`) and tell the human where to set
  the real value. The `gitleaks` workflow scans every push; never weaken or skip it.
- **No AWS account IDs in files.** Read the ID at run time (Terraform: `data.aws_caller_identity`;
  CLI: `aws sts get-caller-identity`) or use a placeholder. `.gitleaks.toml` has a rule for this,
  and the local pre-commit hook runs it before every commit.
- **Never commit Terraform state** (`*.tfstate*`) or `.terraform/`. State files can contain
  private keys in plain text. `.gitignore` blocks them; keep it that way.
- **No client or employer information.** The owner's day job involves confidential client
  systems. Never copy client names, code, configs, diagrams, IP ranges, or numbers into
  this repo. Labs inspired by real work are rebuilt from scratch with generic names.
- **Don't invent results.** No fake outputs, screenshots, or "it works" claims for steps
  that weren't run. If something wasn't verified, say so in the lab README.
- **Ask before anything that costs money or leaves the machine**: creating cloud
  resources, pushing, making the repo public, or deleting anything.

## 2. Structure and naming

Follow the **Naming rules** in [README.md](README.md). In short:

| What | Pattern |
|---|---|
| Lab | `labs/<category>/NN-what-you-build/` — category = the main skill practised |
| Architecture | `architectures/NN-system-name/` |
| Note | `notes/topic-name/` |
| Titles | `# Lab NN — Title`, `# Architecture NN — Title` |
| Terraform files and AWS resource names | Chosen per lab; documented in the lab's README |
| Diagram | `diagram.drawio` (source) + `diagram.png` (export), next to the README; a second page exports to `diagram-<page>.png` (e.g. `diagram-cicd.png`) |

- Create new labs and architectures with the script, never by hand:
  `./new.sh lab <category> <name>` and `./new.sh arch <name>`.
- Allowed lab categories are listed in `new.sh` (`CATEGORIES`). Add a new one there and in
  the README together.
- A lab and its architecture link to each other (the templates have a line for this).
- After adding a lab or architecture, add its row to the tables in [README.md](README.md).
- **One name per topic.** The lab and its architecture share the same folder name and title.
  Folder names say *what* is built; where it runs (e.g. "on Local Kubernetes") goes only at
  the end of the title, never in folder names.

## 3. Writing architectures and labs

Reference example: [architectures/01-gitops-github-actions-argocd](architectures/01-gitops-github-actions-argocd/README.md)
and its [lab](labs/ci-cd/01-gitops-github-actions-argocd/README.md).

- **No template text left behind.** Replace every placeholder with real content as soon as a
  lab or architecture is created. Nothing may still read like the template.
- **Only write what is known.** Sections that can only be written truthfully after building
  (**Problems I hit**, **What I'd do differently**, exact command output, screenshots) get a
  clear note such as "Filled in while building the lab." Never invent them.

**Architecture README** must have:
- **Requirements**: functional and non-functional, stated so they can be checked; say so
  when something (e.g. high availability) is out of scope.
- **Components**: `Component | Tool | What it does` (its role in this system); the *why* lives
  in Key decisions, linked from here.
- **Environment**: for local designs, a "Local environment" table (machine, runtime
  resources, cluster, namespaces, URLs, network exposure) linking to the lab's `SETUP.md`.
- **Request / data flow**: numbered to match the diagram arrows.
- **Key decisions and trade-offs**: options considered, chosen, why, tied to a requirement.
- **Security**, **Scaling and reliability** (a failure → effect → recovery table, backups,
  honest limits), **Cost estimate**, **What I'd improve next**.

Every lab has **two files** (both created by `new.sh`):

**Lab `README.md` = the overview** (what and why; no commands to follow):
- A summary, a link "▶ To run this lab, follow SETUP.md", a **Goal** (the problem, plus
  checkable "at the end" results), **Architecture** bullets that link to the architecture
  doc, **What you'll practise** (skill → step numbers), **Tools and services** with versions,
  **Files in this lab**, **Problems I hit**, **Cost** (linking to SETUP.md's Clean up),
  **What I'd do differently**, and **References** to official documentation only.

**Lab `SETUP.md` = the step-by-step guide** (how; everything a reader runs, in order):
- **What you need** with official install sources; **Part 1 — Prepare** (one tool or account
  per step, each with a check and expected output); **Part 2 — Build and deploy** (every step
  links the files it uses, explains why, and gives the exact commands and expected output;
  never a description-only step. Steps not yet run end-to-end carry a ⚠️ Status note until
  they have been); **Part 3 — Verify** (one numbered step per goal, each with the
  command and expected output); **Part 4 — Clean up** (one numbered step per resource:
  cloud resources, local clusters, GitHub keys, tokens, packages, tools — each with how to
  confirm it is gone); **Troubleshooting**.
- Steps are numbered continuously across all parts, so the README can point to "step 12".
- No step is repeated: a check belongs in Verify, not also in Build and deploy.
- When the guide is long, split it: `SETUP.md` becomes a short index, and each part goes in
  `setup/N-part.md` (plus `setup/troubleshooting.md`), with step numbers continuing across files.

**Terraform:**
- The Terraform layout and AWS naming are chosen **per lab** and documented in that lab's
  README (layout, naming rule, environments). Don't copy one lab's structure into another
  unless the owner asks.
- Check before handing over: `terraform fmt -check -recursive` and `terraform validate`.

**Written for the public:** this repo is public, so every lab is written for a stranger on a
fresh machine, not for the owner's setup.
- Never "already installed": every tool says **where it comes from** (official link) and
  **how to install it**.
- No personal values in instructions: use placeholders like `<your-github-username>`,
  `<your-account-id>`, and say once what they mean.
- Readers work on **their own copy** (fork + enable Actions + clone) when the lab pushes,
  commits, or publishes anything.
- Every check says what the **expected** output looks like.

**General:**
- Steps must be copy-pasteable and in the order they were actually run.
- Pin tool and image versions (Argo CD, kind node image, GitHub Actions, Terraform providers).
  Never use `latest`.
- Every lab must end with cleanup steps that remove everything it created.
- Local labs run on an **Apple Silicon (arm64) Mac with 8 GB RAM**: build images for
  `linux/arm64` (and `linux/amd64` for CI), and keep clusters small.
- Pull base images from **ECR Public** (`public.ecr.aws/...`), not Docker Hub, to avoid rate
  limits in CI.

## 4. Diagrams

- Edit diagrams in draw.io (desktop app or the VS Code extension). Keep `diagram.drawio`
  as the source of truth; never edit only the PNG.
- After changing a diagram, re-export the PNG:
  ```bash
  /Applications/draw.io.app/Contents/MacOS/draw.io -x -f png -s 1.5 -b 10 -o diagram.png diagram.drawio
  ```
  With more than one page, export each page by its number (1-based), e.g.
  `-p 2 -o diagram-cicd.png`.
- Use only the official icons in [assets/icons/](assets/icons/) (see its README for sources
  and licenses). Add new ones from the project's official repo, never from icon sites.
  For AWS, use draw.io's built-in AWS library (official AWS Architecture Icons and groups).
- Arrow colours: blue solid = CI / build (push), purple dashed = GitOps control (pull),
  green = runtime / data. Number the steps of a flow.
- Keep diagrams visual: components, numbered arrows, and a one-line legend. Step details,
  decisions, and trade-offs go in the README, not in the diagram.

## 5. Git

- Commit or push **only when the human asks**. Stage specific files; check `git status`
  and `git diff` first. Never `git add -A` blindly.
- Conventional Commits: `type(scope): summary`, e.g. `feat(ci-cd): add GitOps lab workflow`,
  `docs(architecture): add GitOps pipeline design`. Imperative mood, summary ≤ 72 chars.
- Never force-push unless the human explicitly asks.
- End AI-authored commit messages with:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

## 6. Working style

- Explain each git step briefly, and show changes before pushing.
- Keep explanations short and concrete. Reference files as `path:line`.
