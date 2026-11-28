# Part 1 — Prepare (steps 1–8)

[← Guide index](../SETUP.md) · Next: [Part 2 — Infrastructure →](2-infrastructure.md)

Install the tools, connect to AWS and GitHub, create your two repositories, and give the release
workflow its way into the GitOps repository. Nothing in this part costs money.

## 1. Install the tools

Install [Homebrew](https://brew.sh) first if `brew --version` doesn't work. Then:

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform awscli kubernetes-cli gh
```

**git** comes with Apple's Command Line Tools: if `git --version` says it's missing, click
**Install** when macOS asks (or run `xcode-select --install`).

Check:

```bash
terraform version
aws --version
kubectl version --client
gh --version
git --version
```

Expected: `Terraform v1.17.x` or later, `aws-cli/2.x`, `Client Version: v1.35` or later (kubectl
must be within one minor version of the cluster's 1.36), `gh version 2.x`, and a git version.

Already have Terraform from Homebrew? Update it with `brew upgrade hashicorp/tap/terraform`.

## 2. Connect the AWS CLI to your dev account

Use any sign-in method your account supports, for example IAM Identity Center
(`aws configure sso`) or `aws login`. Name the profile so you can recognise it, then make it the
default for this terminal:

```bash
export AWS_PROFILE=<your-dev-profile>
aws sts get-caller-identity
```

Expected: JSON with your 12-digit `Account` (the dev account) and the `Arn` of your identity.

Use **the same identity for the whole lab**: the identity that creates the cluster (step 12)
becomes its Kubernetes administrator. If you open a new terminal, run the `export` line again.

## 3. Sign in to the GitHub CLI

```bash
gh auth login
```

Answer: **GitHub.com**, **HTTPS**, **Yes** (authenticate Git with your GitHub credentials), and
**Login with a web browser**. Then store your username for later steps:

```bash
export GITHUB_OWNER=<your-github-username>
gh auth status
gh api user --jq .login
```

Expected: `✓ Logged in to github.com account <your-github-username>`, and the last command
prints the same username as `$GITHUB_OWNER`.

## 4. Get this repository (the guide and the Terraform)

Everything for the lab goes in one folder, `~/k8slab01`:

```bash
mkdir -p ~/k8slab01 && cd ~/k8slab01
gh repo clone zaw-minhtay/cloud-infra-labs
ls cloud-infra-labs/labs/kubernetes/01-eks-gitops-image-scanning-signing
```

Expected: `README.md  SETUP.md  setup  terraform  verify`.

You only read and run this repository; you never push to it, so a clone is enough.

## 5. Create your two repositories from the templates

The app and the GitOps configuration live in their **own** repositories, as in a company (see
the [architecture](../../../../architectures/03-eks-gitops-image-scanning-signing/README.md#repositories)).
You make your own copy of each from a template: a fresh repository with the same files, your own
history, and GitHub Actions turned on.

Keep the names `sample-web-app` and `eks-platform-gitops`: Terraform uses them in the AWS trust
policy for the workflows and in Argo CD's settings. Make both **public**: Argo CD reads the GitOps
repository without credentials, and GitHub Actions is free for public repositories.

**Via browser:** open [zaw-minhtay/sample-web-app](https://github.com/zaw-minhtay/sample-web-app)
→ **Use this template** → **Create a new repository** → owner: you, name: `sample-web-app`,
**Public** → **Create repository**. Do the same for
[zaw-minhtay/eks-platform-gitops](https://github.com/zaw-minhtay/eks-platform-gitops). Then
clone both:

```bash
cd ~/k8slab01
gh repo clone "$GITHUB_OWNER/sample-web-app"
gh repo clone "$GITHUB_OWNER/eks-platform-gitops"
```

**Via CLI** (creates and clones in one go):

```bash
cd ~/k8slab01
gh repo create "$GITHUB_OWNER/sample-web-app" --public --template zaw-minhtay/sample-web-app --clone
gh repo create "$GITHUB_OWNER/eks-platform-gitops" --public --template zaw-minhtay/eks-platform-gitops --clone
```

Check:

```bash
ls ~/k8slab01
gh repo view "$GITHUB_OWNER/sample-web-app" --json visibility --jq .visibility
```

Expected: `cloud-infra-labs  eks-platform-gitops  sample-web-app`, and `PUBLIC`.

Creating `sample-web-app` may start a **ci** run that fails at **Get AWS credentials**: the AWS
roles don't exist yet. That is expected; step 15 runs CI again.

## 6. (Optional) Build the app on your machine

Needs Docker Desktop. The image build also runs the tests ([Dockerfile](https://github.com/zaw-minhtay/sample-web-app/blob/main/Dockerfile)):

```bash
cd ~/k8slab01/sample-web-app
docker build --build-arg APP_COMMIT=local -t sample-web-app:local .
```

Expected (near the end): `Tests run: 12, Failures: 0, Errors: 0, Skipped: 0`, then
`BUILD SUCCESS`. A `WARN ... Storage error: SdkClientException` line is expected: one test
simulates DynamoDB being down. To run the app with DynamoDB Local, follow the app's
[README](https://github.com/zaw-minhtay/sample-web-app#run-it-on-your-machine-with-dynamodb-local).

## 7. Protect the GitOps repository

Two settings make the release workflow's pull requests safe: **CODEOWNERS** names a reviewer for
every path except dev's version, and **branch protection** makes every change to `main` a pull
request that a code owner must approve where one is named
([CODEOWNERS](https://github.com/zaw-minhtay/eks-platform-gitops/blob/main/.github/CODEOWNERS)).

First put your username in CODEOWNERS (before protection is on, so you can still push):

```bash
cd ~/k8slab01/eks-platform-gitops
sed -i '' "s/your-github-username/$GITHUB_OWNER/" .github/CODEOWNERS
grep -v '^#' .github/CODEOWNERS | grep .
git commit -am "chore: set the code owner"
git push origin main
```

Expected: the `grep` shows `*  @<your-github-username>` and the line
`/manifests/sample-web-app/overlays/dev/` (no owner), and the push succeeds.

Then turn on protection:

**Via browser:** `eks-platform-gitops` → **Settings** → **Branches** → **Add classic branch
protection rule** → branch name pattern `main` → tick **Require a pull request before merging**,
set **Required approvals** to **0**, tick **Require review from Code Owners** → **Create**.

**Via CLI:**

```bash
gh api -X PUT "repos/$GITHUB_OWNER/eks-platform-gitops/branches/main/protection" --input - <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "require_code_owner_reviews": true
  },
  "restrictions": null
}
EOF
```

Check:

```bash
gh api "repos/$GITHUB_OWNER/eks-platform-gitops/branches/main/protection" \
  --jq '.required_pull_request_reviews | [.required_approving_review_count, .require_code_owner_reviews]'
```

Expected: `[0,true]`. With 0 required approvals, only paths that have a code owner need a review:
the release workflow's pull request (dev's version only) can merge on its own, and anything else
waits for you.

## 8. Create the GitHub App for releases

The release workflow in `sample-web-app` must open and merge a pull request in
`eks-platform-gitops`. A GitHub App gives it a token that lasts one hour and works only on that
one repository. GitHub has no CLI for creating Apps, so this part is browser only.

**Create the App (browser):** GitHub → your profile picture → **Settings** → **Developer
settings** → **GitHub Apps** → **New GitHub App**:

| Field | Value |
|---|---|
| GitHub App name | `<your-github-username>-gitops-release` (must be unique on GitHub) |
| Homepage URL | `https://github.com/<your-github-username>/sample-web-app` |
| Webhook | Untick **Active** (the App needs no events) |
| Repository permissions | **Contents: Read and write**, **Pull requests: Read and write** (Metadata: Read-only is added for you) |
| Where can this GitHub App be installed? | **Only on this account** |

Click **Create GitHub App**. On the App's page:

1. Copy the **Client ID** (starts with `Iv`).
2. Under **Private keys**, click **Generate a private key**. A `.pem` file downloads.
3. In the left menu, **Install App** → **Install** → **Only select repositories** →
   `eks-platform-gitops` → **Install**.

**Store the Client ID and key in `sample-web-app`:**

**Via browser:** `sample-web-app` → **Settings** → **Secrets and variables** → **Actions**:
- **Variables** tab → **New repository variable**: name `GITOPS_APP_CLIENT_ID`, value the
  Client ID.
- **Secrets** tab → **New repository secret**: name `GITOPS_APP_PRIVATE_KEY`, value the whole
  content of the `.pem` file (open it in a text editor and copy everything, including the
  `-----BEGIN` and `-----END` lines).

**Via CLI:**

```bash
cd ~/k8slab01/sample-web-app
gh variable set GITOPS_APP_CLIENT_ID --body "<client-id>"
gh secret set GITOPS_APP_PRIVATE_KEY < ~/Downloads/<your-github-username>-gitops-release.*.private-key.pem
```

Then delete the downloaded key: it now lives only in GitHub, and you can generate a new one at
any time.

```bash
rm ~/Downloads/<your-github-username>-gitops-release.*.private-key.pem
```

Check:

```bash
gh variable list
gh secret list
```

Expected: `GITOPS_APP_CLIENT_ID` with your Client ID, and `GITOPS_APP_PRIVATE_KEY` (secrets show
only their name and date, never the value).

Next: [Part 2 — Infrastructure →](2-infrastructure.md)
