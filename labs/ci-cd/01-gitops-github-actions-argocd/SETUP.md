# Step-by-step guide — Lab 01 GitOps Pipeline on Local Kubernetes

Everything from a fresh Mac to a working GitOps deployment, in order. For what this lab is
and why, see the [overview](README.md).

Written for **macOS on Apple Silicon** (M1 or later). Tested on an 8 GB RAM Mac with Docker
Desktop 29.9.

> Throughout this guide, `<your-github-username>` means **your own** GitHub username.

| Part | Steps | What you'll do |
|---|---|---|
| [1. Prepare your Mac](#part-1--prepare-your-mac) | 1–6 | Install the tools and test them (~30 min, once) |
| [2. Build and deploy](#part-2--build-and-deploy) | 7–15 | Build the app, CI, and Argo CD, then run the full GitOps loop |
| [3. Verify](#part-3--verify) | 16–20 | Prove each goal: running, in sync, latest version, self-heal, rollback |
| [4. Clean up](#part-4--clean-up) | 21–24 | Delete the cluster, the token, the image, and the tools |

## What you need

| Tool | Used for | Install from (official) |
|---|---|---|
| Homebrew | Installs the command-line tools below | [brew.sh](https://brew.sh) — step 1 |
| Docker Desktop | Runs containers and the kind cluster | [docs.docker.com](https://docs.docker.com/desktop/setup/install/mac-install/) — step 2 |
| kubectl (+ Kustomize) | Talks to Kubernetes, renders manifests | Included with Docker Desktop |
| kind | Runs a Kubernetes cluster inside Docker | [kind.sigs.k8s.io](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) via Homebrew — step 3 |
| argocd CLI | Logs in to and controls Argo CD | [argo-cd.readthedocs.io](https://argo-cd.readthedocs.io/en/stable/cli_installation/) via Homebrew — step 3 |
| GitHub CLI (`gh`) | Logs in to GitHub from the terminal | [cli.github.com](https://cli.github.com) via Homebrew — step 3 |
| git | Version control | Apple Command Line Tools — step 3 |
| A GitHub account | Hosts your copy of the repo, runs GitHub Actions, stores images (GHCR) | [github.com/signup](https://github.com/signup) (free) — step 4 |

Everything in this lab runs locally or on GitHub's free tier. **Cost: $0.**

> **Docker Desktop license:** free for personal use, education, non-commercial open source,
> and small businesses. Larger companies need a paid subscription — check
> [Docker's pricing page](https://www.docker.com/pricing/) if you use a work Mac.

---

## Part 1 — Prepare your Mac

### 1. Install Homebrew

Skip this step if `brew --version` already prints a version.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

This is the official command from [brew.sh](https://brew.sh). When it finishes, it prints a
**Next steps** section with two commands that add `brew` to your PATH. Run them, then check:

```bash
brew --version
```

### 2. Install Docker Desktop and give it enough resources

1. Download **Docker Desktop for Mac with Apple silicon** from
   [docs.docker.com](https://docs.docker.com/desktop/setup/install/mac-install/) and install it.
2. Open **Docker Desktop** from Applications, accept the terms, and wait until it says
   **Engine running**.
3. Go to **Settings → VM Resources** and set:

   | Setting | Value | Why |
   |---|---|---|
   | CPU limit | 4 | Leaves 2 cores for macOS |
   | Memory limit | 5 GB | kind + Argo CD + the app need about 3–4 GB |
   | Swap | 1 GB | Headroom when memory is tight |

4. Click **Apply & restart**.

Check it works:

```bash
docker info --format '{{.NCPU}} CPUs, {{.MemTotal}} bytes memory'
docker run --rm hello-world
```

Expected: `4 CPUs, …`, then a `Hello from Docker!` message.

> **8 GB Mac tip:** close Chrome tabs, Slack, and other heavy apps while the cluster runs.
> When you finish for the day, delete the cluster ([step 21](#21-delete-the-cluster)) to free memory.

### 3. Install the command-line tools

```bash
brew install kind argocd gh
```

**git:** run `git --version`. If git is missing, macOS offers to install the **Command Line
Tools** — click **Install** (or run `xcode-select --install`).

**kubectl** comes with Docker Desktop. If `kubectl version --client` says
`command not found`, install it with `brew install kubectl`.

### 4. Log in to GitHub

You need a GitHub account ([sign up free](https://github.com/signup)). Then log in from the
terminal:

```bash
gh auth login
```

Answer the prompts: **GitHub.com** → **HTTPS** → **Yes** (authenticate Git) → **Login with a
web browser**, then paste the one-time code shown in the terminal into the browser.

### 5. Check every tool

```bash
docker version --format 'docker {{.Client.Version}}'
kubectl version --client
kind version
argocd version --client --short
git --version
gh auth status
```

Expected: each command prints a version, and `gh auth status` shows
`Logged in to github.com account <your-github-username>`.

Versions used when this lab was written (newer versions should also work):

| Tool | Version |
|---|---|
| Docker | 29.9.2 |
| kubectl | 1.36.1 (Kustomize 5.8.1) |
| kind | 0.33.0 |
| argocd CLI | 3.6.2 |

### 6. Smoke test: create and delete a throwaway cluster

This proves Docker, kind, and kubectl work together before the real lab.

```bash
kind create cluster --name smoke-test
kubectl get nodes
kind delete cluster --name smoke-test
```

Expected: `kubectl get nodes` shows one node, `smoke-test-control-plane`, with
`STATUS` = `Ready`.

---

## Part 2 — Build and deploy

> ⚠️ **Status:** these steps are written but not yet run end-to-end. This note is removed
> once every step has been run and its output checked.

Run every command from the lab folder (`cloud-infra-labs/labs/ci-cd/01-gitops-github-actions-argocd`)
unless a step says otherwise.

### 7. Get your own copy of this repo

The pipeline pushes images to *your* GHCR and commits to *your* repo, so you need your own
copy.

1. On GitHub, click **Fork** on this repository.
2. In your fork, open the **Actions** tab and click **I understand my workflows, go ahead and
   enable them** (GitHub disables workflows in new forks).
3. Clone your fork:
   ```bash
   git clone https://github.com/<your-github-username>/cloud-infra-labs.git
   cd cloud-infra-labs/labs/ci-cd/01-gitops-github-actions-argocd
   ```

### 8. Create the cluster

File: [cluster/kind-config.yaml](cluster/kind-config.yaml), a single-node cluster named
`gitops-lab`.

```bash
kind create cluster --config cluster/kind-config.yaml
kubectl get nodes
```

Expected: kind ends with `Set kubectl context to "kind-gitops-lab"`, and `kubectl get nodes`
shows `gitops-lab-control-plane` with `STATUS` = `Ready` (this can take up to a minute).

### 9. Test and run the app locally

Files in [app/](app/):

| File | What it is |
|---|---|
| [server.py](app/server.py) | The web app (Python standard library only). `/` shows the message and version; `/healthz` returns `ok` for the probes |
| [test_server.py](app/test_server.py) | Unit tests, also run by CI |
| [Dockerfile](app/Dockerfile) | Builds the image on `python:3.13-slim`, runs as a non-root user |
| [.dockerignore](app/.dockerignore) | Keeps the tests out of the image |

Run the tests (`python3` comes with the Command Line Tools from step 3):

```bash
python3 -m unittest discover -s app -v
```

Expected: `Ran 4 tests`, then `OK`.

Build the image and run it on your Mac before any CI, so problems show up here first:

```bash
docker build -t gitops-demo:local --build-arg APP_VERSION=local app/
docker run --rm -d --name gitops-demo -p 8080:8080 gitops-demo:local
curl http://localhost:8080
curl http://localhost:8080/healthz
docker stop gitops-demo
```

Expected: `Hello from GitOps! version=local`, then `ok`.

### 10. Review the Kubernetes manifests

Files in [deploy/](deploy/), which is the desired state Argo CD applies:

| File | What it is |
|---|---|
| [kustomization.yaml](deploy/kustomization.yaml) | Lists the manifests, sets namespace `demo`, and holds the image name and tag that CI updates |
| [deployment.yaml](deploy/deployment.yaml) | 2 replicas, rolling update with no downtime, readiness and liveness probes on `/healthz`, non-root and read-only container, pull secret `ghcr-pull` |
| [service.yaml](deploy/service.yaml) | ClusterIP Service `demo`, port 80 → container port 8080 |

Render the manifests the way Argo CD will see them:

```bash
kubectl kustomize deploy/
```

Expected: a `Service` and a `Deployment`, both in namespace `demo`. The image is whatever
the last CI run in the repo you forked wrote there (for example
`ghcr.io/zaw-minhtay/gitops-demo:1030a7c`). Your own CI run in the next step replaces it with
your image.

### 11. Run the CI workflow

File: [.github/workflows/ci-cd-01-gitops.yml](../../../.github/workflows/ci-cd-01-gitops.yml)
(at the repo root, where GitHub looks for workflows). On every push to `main` that changes
this lab's `app/`, it:

1. runs the tests;
2. builds the image for `linux/arm64` and `linux/amd64`;
3. pushes it to `ghcr.io/<your-github-username>/gitops-demo`, tagged with the short commit SHA;
4. writes the new image name and tag into `deploy/kustomization.yaml` and commits it.

Changes to `deploy/` do **not** trigger CI, so the tag commit and Git rollbacks (step 20)
never cause a rebuild.

Nothing in `app/` has changed yet, so run the workflow once by hand on GitHub:

1. Open `https://github.com/<your-github-username>/cloud-infra-labs` and click the
   **Actions** tab.
2. In the left sidebar, click **ci-cd-01-gitops**.
3. On the right, click **Run workflow**, keep **Branch: main**, and click the green
   **Run workflow** button. (This button exists because the workflow has
   `workflow_dispatch:`.)
4. After a few seconds a new run appears at the top of the list (a yellow dot means it is
   running). Click it, then click the job **build-and-release** to watch each step live.

Expected: every step gets a green ✓ and the run shows **Success**. Building arm64 on GitHub's
amd64 runners uses emulation, so this takes a few minutes.

Pull the commit CI made and check the new tag:

```bash
git pull
grep -A2 "name: gitops-demo" deploy/kustomization.yaml
```

Expected: `newName: ghcr.io/<your-github-username>/gitops-demo` and `newTag:` followed by a
7-character commit SHA. On GitHub, your profile → **Packages** now shows `gitops-demo`.

### 12. Install Argo CD

Install Argo CD v3.6.2 (the same version as the CLI from step 3):

```bash
kubectl create namespace argocd
kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.6.2/manifests/install.yaml
kubectl wait -n argocd --for=condition=Available deployment --all --timeout=300s
kubectl get pods -n argocd
```

`--server-side` is needed because Argo CD's CustomResourceDefinitions are too large for
client-side apply.

Expected: `condition met` for each deployment, then all `argocd-…` pods `Running`.

Open the Argo CD UI in a **second terminal** and leave it running:

```bash
kubectl port-forward -n argocd svc/argocd-server 8443:443
```

Back in the first terminal, get the admin password and log in:

```bash
argocd admin initial-password -n argocd
argocd login localhost:8443 --username admin --insecure
```

Paste the password when asked. `--insecure` is needed because this local Argo CD uses a
self-signed certificate; never use it against a real server.

Expected: `'admin:login' logged in successfully`. You can also open `https://localhost:8443`
in a browser (accept the certificate warning) and log in as `admin`.

### 13. Give the cluster read-only access to your image

Your image in GHCR is private (packages have their own visibility, separate from the repo),
so the cluster needs a read-only token to pull it. Argo CD needs no credentials: it reads
your public repo over HTTPS.

1. On GitHub, open **Settings → Developer settings → Personal access tokens → Tokens
   (classic)** → **Generate new token (classic)**. GHCR only accepts classic tokens.
2. Note: `gitops-lab GHCR pull`. Expiration: **7 days**. Scopes: tick **only**
   `read:packages`.
3. Click **Generate token** and copy it.

Store it in the cluster as the `ghcr-pull` secret. `read -s` keeps the token out of your
screen and shell history:

```bash
kubectl create namespace demo
read -s GHCR_TOKEN
kubectl create secret docker-registry ghcr-pull -n demo \
  --docker-server=ghcr.io \
  --docker-username=<your-github-username> \
  --docker-password="$GHCR_TOKEN"
unset GHCR_TOKEN
```

After `read -s GHCR_TOKEN`, paste the token and press **Enter** (nothing is shown).

Expected: `namespace/demo created`, then `secret/ghcr-pull created`.

<details>
<summary><b>Only if your copy of the repo is private:</b> give Argo CD a read-only deploy key</summary>

A fork of a public repo is always public, so most readers skip this. If you copied the repo
into a **private** repo instead (for example with **Import repository**), Argo CD needs a key
to read it:

```bash
ssh-keygen -t ed25519 -C argocd-gitops-lab -f ~/.ssh/argocd-gitops-lab -N ""
gh repo deploy-key add ~/.ssh/argocd-gitops-lab.pub --repo <your-github-username>/cloud-infra-labs --title argocd-gitops-lab
argocd repo add git@github.com:<your-github-username>/cloud-infra-labs.git --ssh-private-key-path ~/.ssh/argocd-gitops-lab
```

The key has no passphrase because Argo CD must use it unattended. GitHub deploy keys are
read-only unless you add `--allow-write`, which you must not.

Expected: `Repository 'git@github.com:…' added`. In step 14, use the SSH command for private
repos.

</details>

### 14. Create the Argo CD Application

File: [argocd/application.yaml](argocd/application.yaml). It points Argo CD at this lab's
`deploy/` folder on `main`, deploys into namespace `demo`, and turns on auto-sync, self-heal,
and prune.

Apply it with your username filled in (the file in Git keeps the placeholder):

```bash
GH_USER=$(gh api user --jq .login)
sed "s/your-github-username/${GH_USER}/" argocd/application.yaml | kubectl apply -f -
```

<details>
<summary><b>Only if your copy of the repo is private:</b> use the SSH URL instead</summary>

Use this instead of the command above, so Argo CD connects with the deploy key from step 13:

```bash
GH_USER=$(gh api user --jq .login)
sed "s#https://github.com/your-github-username/#git@github.com:${GH_USER}/#" argocd/application.yaml | kubectl apply -f -
```

</details>

Wait for the first sync:

```bash
argocd app wait demo --health --timeout 300
kubectl get pods -n demo
```

Expected: `application.argoproj.io/demo created`; `argocd app wait` ends with
`Sync Status: Synced` and `Health Status: Healthy`; 2 `demo-…` pods are `Running`.

### 15. Run the full loop

Change the app's message, push, and watch the change flow through to the cluster.

1. Change the message and run the tests:
   ```bash
   sed -i '' 's/Hello from GitOps!/Hello from GitOps v2!/' app/server.py
   python3 -m unittest discover -s app -v
   ```
2. Commit and push:
   ```bash
   git add app/server.py
   git commit -m "feat(ci-cd): change demo message"
   git push
   ```
3. Watch CI build the new image and commit the new tag: on GitHub, open the **Actions** tab
   → **ci-cd-01-gitops** → the newest run (started by your push) → **build-and-release**.
   Wait until every step has a green ✓.
4. Argo CD checks Git every 3 minutes. To check right away, and watch the pods roll:
   ```bash
   argocd app get demo --refresh
   kubectl get pods -n demo --watch
   ```
   Press `Ctrl+C` when two new pods are `Running`.
5. Open a tunnel to the app in a **third terminal** (leave it running) and check the page:
   ```bash
   kubectl port-forward -n demo svc/demo 8080:80
   ```
   ```bash
   curl http://localhost:8080
   ```

Expected: `Hello from GitOps v2! version=` followed by the new commit SHA. You never ran
`kubectl apply` for the app: Git changed, and the cluster followed.

---

## Part 3 — Verify

Run these after step 15. Each one proves one of the lab's goals.

### 16. Check the app is running

```bash
kubectl get pods -n demo
```

Expected: 2 pods with `STATUS` = `Running` and `READY` = `1/1`.

### 17. Check Argo CD is in sync

```bash
argocd app get demo
```

Expected: `Sync Status: Synced` and `Health Status: Healthy`.

### 18. Check the latest version is live

Open a tunnel to the app in one terminal (leave it running):

```bash
kubectl port-forward -n demo svc/demo 8080:80
```

In a second terminal, compare the page with the tag in Git:

```bash
curl http://localhost:8080
grep newTag deploy/kustomization.yaml
```

Expected: the version shown by `curl` is the same commit SHA as `newTag`.

### 19. Check self-heal reverts manual changes

Change the cluster by hand, then watch:

```bash
kubectl scale deployment demo -n demo --replicas=5
kubectl get deployment demo -n demo --watch
```

Expected: `READY` briefly goes towards 5, then Argo CD sets it back to `2/2` within about a
minute. Press `Ctrl+C` to stop watching.

### 20. Check rollback with Git

Find the last commit that changed the image tag, revert it, and push:

```bash
git pull
git log --oneline -- deploy/
git revert <commit-from-the-top-line>
git push
```

Expected: within a few minutes Argo CD syncs the previous tag (`argocd app get demo`), and
`curl http://localhost:8080` shows the previous version. CI does not run, because it ignores
changes to `deploy/` (step 11).


---

## Part 4 — Clean up

Remove everything the lab created, so nothing keeps using memory, access, or storage.

### 21. Delete the cluster

First press `Ctrl+C` in the terminals running `kubectl port-forward`. Then:

```bash
kind delete cluster --name gitops-lab
kind get clusters
```

Expected: `gitops-lab` is no longer listed (or `No kind clusters found.`).

### 22. Delete the GHCR token

The `read:packages` token from step 13 is no longer needed.

1. On GitHub, open **Settings → Developer settings → Personal access tokens → Tokens (classic)**.
2. Find the token you created for this lab and click **Delete**.

Expected: the token is no longer in the list.

<details>
<summary><b>Only if you added a deploy key in step 13:</b> delete it</summary>

```bash
gh repo deploy-key list --repo <your-github-username>/cloud-infra-labs
gh repo deploy-key delete <key-id> --repo <your-github-username>/cloud-infra-labs
rm ~/.ssh/argocd-gitops-lab ~/.ssh/argocd-gitops-lab.pub
```

Expected: `gh repo deploy-key list` no longer shows `argocd-gitops-lab`, and
`ls ~/.ssh/argocd-gitops-lab*` says `No such file or directory`.

</details>

### 23. Delete the container image (optional)

1. On GitHub, open your profile → **Packages** → the lab's image.
2. Click **Package settings** → **Delete this package**, and confirm.

Expected: the package is no longer listed under **Packages**.

### 24. Remove the tools (optional)

Skip any tool you use for other work.

```bash
brew uninstall kind argocd gh
```

To remove Docker Desktop: open it → **Troubleshoot** (bug icon) → **Uninstall**.

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `command not found: brew` | Homebrew is not on your PATH | Run the two **Next steps** commands from the Homebrew installer, or open a new terminal |
| `Cannot connect to the Docker daemon` | Docker Desktop is not running | Open Docker Desktop and wait for **Engine running** |
| `kind create cluster` hangs or fails | Not enough memory for Docker | Raise the memory limit (step 2) and close other apps |
| `kubectl` talks to the wrong cluster | Several clusters in your kubeconfig | `kubectl config get-contexts`, then `kubectl config use-context kind-<name>` |
| `gh auth status` says you are not logged in | Login not finished | Run `gh auth login` again (step 4) |
| `docker run` fails with `port is already allocated` | Something already uses port 8080 (often a `kubectl port-forward`) | Stop it with `Ctrl+C`, or use another port: `-p 8081:8080` |
| CI step **Build and push** fails with `denied` | A `gitops-demo` package already exists and isn't linked to this repo | On GitHub, open the package → **Package settings → Manage Actions access** → add your repo with **Write** |
| CI step **Commit the new image tag** fails on `git push` | Branch protection on `main` blocks the bot | Allow GitHub Actions to push to `main`, or remove the rule for this lab |
| Pods stuck in `ImagePullBackOff` | Wrong or expired token in `ghcr-pull` | `kubectl describe pod -n demo <pod>` shows the error; recreate the secret (step 13a) |
| Pods fail with `exec format error` | Image built for the wrong CPU (amd64 only) | Check the workflow's `platforms:` includes `linux/arm64` |
| `argocd app get demo` shows `ComparisonError` / `repository not found` | Wrong username in `repoURL`, or the repo is private | `kubectl get application demo -n argocd -o jsonpath='{.spec.source.repoURL}'` to check the URL. For a private repo, add the deploy key and use the SSH URL (the private-repo sections in steps 13 and 14) |
