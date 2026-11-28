# Part 3 — Release (steps 14–18)

[← Part 2](2-infrastructure.md) · [Guide index](../SETUP.md) · Next: [Part 4 — Verify →](4-verify.md)

Connect the workflows to AWS, build the first image, release it as `v1.0.0`, and watch Argo CD
deploy it. The workflows are in your `sample-web-app`:
[ci.yml](https://github.com/zaw-minhtay/sample-web-app/blob/main/.github/workflows/ci.yml) and
[release.yml](https://github.com/zaw-minhtay/sample-web-app/blob/main/.github/workflows/release.yml).

## 14. Give the workflows their AWS roles

Each workflow gets short-lived AWS credentials through OIDC for one IAM role: `ci` can only push
to `candidate`, and only from `main`; `release` can read `candidate` and its scan, push to
`release`, and sign, and only from a `v*` tag. The role ARNs contain your account ID, so they go
in GitHub settings, not in a file.

**Via console:** **IAM** → **Roles** → `k8slab01-dev-github-ci` → copy the **ARN**. In GitHub,
`sample-web-app` → **Settings** → **Secrets and variables** → **Actions** → **Variables** →
**New repository variable**: name `AWS_CI_ROLE_ARN`, value the ARN. Do the same with
`k8slab01-dev-github-release` as `AWS_RELEASE_ROLE_ARN`.

**Via CLI** (from the platform stack's folder, with step 9's values):

```bash
cd ~/k8slab01/cloud-infra-labs/labs/kubernetes/01-eks-gitops-image-scanning-signing/terraform/stacks/3-platform
gh variable set AWS_CI_ROLE_ARN --repo "$GITHUB_OWNER/sample-web-app" --body "$(terraform output -raw github_ci_role_arn)"
gh variable set AWS_RELEASE_ROLE_ARN --repo "$GITHUB_OWNER/sample-web-app" --body "$(terraform output -raw github_release_role_arn)"
```

Check:

```bash
gh variable list --repo "$GITHUB_OWNER/sample-web-app"
```

Expected: three variables, `AWS_CI_ROLE_ARN`, `AWS_RELEASE_ROLE_ARN`, and
`GITOPS_APP_CLIENT_ID`.

## 15. Build the first image (CI)

A push to `main` runs **ci**: it builds the image (which runs the tests), pushes it to
`candidate` tagged with the commit ID, and Inspector scans it. It deploys nothing. Push an empty
commit to start it:

```bash
cd ~/k8slab01/sample-web-app
git pull
git commit --allow-empty -m "chore: first CI run"
git push origin main
sleep 10
gh run watch --exit-status "$(gh run list --workflow ci.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
```

Takes 3–5 minutes. Expected: the run ends with `✓` and no error.

**Via browser:** `sample-web-app` → **Actions** → **ci** → the newest run: a green check mark.
Its summary shows the image it pushed.

Check the image is in `candidate`, tagged with your latest commit ID:

**Via console:** **ECR** → **Private registry** → **Repositories** →
`k8slab01-dev/candidate/sample-web-app`. Expected: one image whose tag is your commit ID (compare
with `git rev-parse HEAD`). After a few minutes its scan status shows the scan has run.

**Via CLI:**

```bash
git rev-parse HEAD
aws ecr describe-images --repository-name k8slab01-dev/candidate/sample-web-app \
  --query "imageDetails[].imageTags[]" --output text
```

Expected: the same commit ID twice.

## 16. Release version 1.0.0

A version tag runs **release**: it waits for that commit's scan, stops on any critical
vulnerability, copies the same image to `release` as `1.0.0` (ECR signs it), creates a GitHub
Release, and opens and merges a pull request in `eks-platform-gitops` that sets `1.0.0` and the
digest in the dev overlay.

```bash
git tag v1.0.0
git push origin v1.0.0
sleep 10
gh run watch --exit-status "$(gh run list --workflow release.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
```

Takes about 5 minutes, mostly waiting for the scan. Expected: the run ends with `✓`.

**Via browser:** **Actions** → **release** → the newest run: green. Its summary shows the scan's
findings by severity and the merged pull request. Also check:
- `sample-web-app` → **Releases**: `v1.0.0`, with the image and its digest.
- `eks-platform-gitops` → **Pull requests** → **Closed**: **Deploy sample-web-app 1.0.0 to dev**,
  merged by your App (`<your-github-username>-gitops-release[bot]`).

If the run stops at the scan step with critical vulnerabilities, a base image or library has a
new critical CVE: see [troubleshooting](troubleshooting.md).

Check the release image and its signature:

**Via console:** **ECR** → **Repositories** → `k8slab01-dev/release/sample-web-app`. Expected:
one image tagged `1.0.0`; open it to see its signing status, **Complete**.

**Via CLI:**

```bash
aws ecr describe-images --repository-name k8slab01-dev/release/sample-web-app \
  --query "imageDetails[].imageTags[]" --output text
aws ecr describe-image-signing-status --repository-name k8slab01-dev/release/sample-web-app \
  --image-id imageTag=1.0.0 --query "signingStatuses[].status" --output text
```

Expected: `1.0.0`, then `COMPLETE`.

## 17. Watch Argo CD deploy it

Argo CD checks your GitOps repository every 3 minutes, sees the merged change, and deploys
`1.0.0` into `app-dev`. This time Gatekeeper lets the pods in: the image is from `release`,
pinned by digest, and Ratify finds a valid signature from your Signer profile.

To skip the wait, ask Argo CD to check Git now:

```bash
kubectl -n argocd annotate application sample-web-app argocd.argoproj.io/refresh=normal --overwrite
```

**Via browser:** the Argo CD UI (step 13) → **sample-web-app**. Expected: **Healthy** and
**Synced**, with two pods.

**Via CLI:**

```bash
kubectl -n argocd get application sample-web-app
kubectl -n app-dev get pods -o wide
```

Expected: `Synced` and `Healthy`, and two `sample-web-app-…` pods, `Running` and `1/1` ready, on
two different nodes (one per Availability Zone; compare with
`kubectl get nodes -L topology.kubernetes.io/zone`).

## 18. Use the app

The AWS Load Balancer Controller created an Application Load Balancer from the app's Ingress.

**Via console:** **EC2** → **Load Balancers** → the one whose name starts with `k8s-appdev-`
→ copy its **DNS name**. Your `<app_url>` is `http://` + that name.

**Via CLI:**

```bash
APP_URL="http://$(kubectl -n app-dev get ingress sample-web-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "$APP_URL"
```

Expected: `http://k8s-appdev-samplewe-….ap-northeast-1.elb.amazonaws.com`. A new load
balancer's address can take 2–3 minutes to start answering.

**Via browser:** open `<app_url>/`. Expected: the **Items** page, with
`sample-web-app · 1.0.0 (<commit-id>)` at the top: the version from the release and the commit
it was built from. Add an item, then **Edit** and **Save** it. Reload the page: the item is still
there (it is stored in DynamoDB).

**Via CLI:**

```bash
curl -s "$APP_URL/info"; echo
curl -s -X POST "$APP_URL/items" -H 'Content-Type: application/json' -d '{"name":"Book","description":"Read later"}'; echo
curl -s "$APP_URL/items"; echo
```

Expected:

```
{"version":"1.0.0","app":"sample-web-app","commit":"<commit-id>"}
{"id":"…","name":"Book","description":"Read later","createdAt":"…","updatedAt":"…"}
[…,{"id":"…","name":"Book","description":"Read later","createdAt":"…","updatedAt":"…"}]
```

Keep `APP_URL` set for Part 4.

Next: [Part 4 — Verify →](4-verify.md)
