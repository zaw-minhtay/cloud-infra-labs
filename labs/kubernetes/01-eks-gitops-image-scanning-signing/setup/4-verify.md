# Part 4 — Verify (steps 19–24)

[← Part 3](3-release.md) · [Guide index](../SETUP.md) · Next: [Part 5 — Clean up →](5-clean-up.md)

Prove each guardrail works. Version `1.0.0` should be running (step 18). Run the commands with
step 9's values set and `APP_URL` from step 18.

## 19. Watch the scan stop a release

You add a library with a famous critical vulnerability to the app: Log4j 2.14.1, which has
**Log4Shell** (CVE-2021-44228). CI builds and pushes the image as usual, and Amazon Inspector
finds the vulnerability. When you tag a release, the release workflow stops at the scan check:
the image never reaches the `release` repository, so it is never signed and can never run in
the cluster.

The app doesn't use the library (it logs with Logback); it is only packed into the image, which
is enough for the scan to find it.

**1. Add the vulnerable library.** In `~/k8slab01/sample-web-app/pom.xml`, add this right after
the `dynamodb` dependency:

```xml
        <!-- DEMO ONLY: Log4Shell (CVE-2021-44228). Inspector rates it critical, so a release stops. -->
        <dependency>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-core</artifactId>
            <version>2.14.1</version>
        </dependency>
```

Commit it to `main` and push. A push to `main` only builds and scans; it deploys nothing:

```bash
cd ~/k8slab01/sample-web-app
git switch main && git pull
git commit -am "chore: add log4j-core 2.14.1 (Log4Shell) for the scan demo"
git push origin main
```

**2. Wait for CI** (3–5 minutes).

**Via browser:** `sample-web-app` → **Actions** → **ci** → the newest run. Expected: a green
check mark. The tests still pass: the library is only added, never used.

**Via CLI:**

```bash
sleep 10
gh run watch --exit-status "$(gh run list --workflow ci.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
```

Expected: the run ends with `✓` and no error.

**3. See what Inspector found.** The scan starts when the image is pushed and takes a few
minutes.

**Via console:** **Amazon Inspector** → **Findings** → **By container image** → select the image
in `k8slab01-dev/candidate/sample-web-app` whose tag is your latest commit ID. Expected: one or
more **Critical** findings, including **CVE-2021-44228** in `log4j-core` 2.14.1.

**Via CLI:**

```bash
aws ecr describe-image-scan-findings --repository-name k8slab01-dev/candidate/sample-web-app \
  --image-id imageTag="$(git rev-parse HEAD)" \
  --query "imageScanFindings.enhancedFindings[?severity=='CRITICAL'].[packageVulnerabilityDetails.vulnerabilityId, packageVulnerabilityDetails.vulnerablePackages[0].name, packageVulnerabilityDetails.vulnerablePackages[0].version]" \
  --output text
```

Expected: at least one line with `CVE-2021-44228`, a `log4j-core` package, and `2.14.1`. If
you get `ScanNotFoundException` or nothing at all, the scan hasn't finished: wait a minute and
run it again.

**4. Try to release it** as version `1.1.0`:

```bash
git tag v1.1.0
git push origin v1.1.0
```

**Via browser:** **Actions** → **release** → the newest run. Expected: a red cross. Open the run:
the failed step is **Wait for the Inspector scan, and stop on critical findings**, with the
message `… critical vulnerabilities. Nothing is released. Fix them, push to main, and tag the new
commit.`

**Via CLI:**

```bash
sleep 10
RUN=$(gh run list --workflow release.yml --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch --exit-status "$RUN"
gh run view "$RUN" --log-failed | grep "critical vulnerabilities"
```

Expected: `gh run watch` ends with `X` and an error, and the last command prints the message
above.

**5. Check that nothing was released or deployed.**

**Via console:**
- **ECR** → **Private registry** → **Repositories** → `k8slab01-dev/release/sample-web-app`.
  Expected: only the image tagged `1.0.0`, no `1.1.0`.
- On GitHub, `sample-web-app` → **Releases**: no `v1.1.0` release (the tag exists, the release
  doesn't). `eks-platform-gitops` → **Pull requests** → **Closed**: no pull request for `1.1.0`.
- **Via browser:** the app's page still shows `sample-web-app · 1.0.0` at the top.

**Via CLI:**

```bash
aws ecr describe-images --repository-name k8slab01-dev/release/sample-web-app \
  --query "imageDetails[].imageTags[]" --output text
curl -s "$APP_URL/info"; echo
```

Expected: `1.0.0` only, and `"version":"1.0.0"`.

**6. Fix it and release again.** Undo the change and push; wait for CI as in point 2; then
release the fixed commit as the **next** version, `1.1.1`:

```bash
git revert --no-edit HEAD
git push origin main
sleep 10
gh run watch --exit-status "$(gh run list --workflow ci.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
git tag v1.1.1
git push origin v1.1.1
sleep 10
gh run watch --exit-status "$(gh run list --workflow release.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
```

Expected: both runs end with `✓`, a pull request in `eks-platform-gitops` named **Deploy
sample-web-app 1.1.1 to dev** is merged, and within about 3 minutes the app's page (and
`curl -s "$APP_URL/info"`) shows version `1.1.1`.

Version `1.1.0` is never released, and the number isn't reused: its tag stays as the record of
a stopped release, and the `release` repository's tags can't be overwritten anyway.

**What this proves:** a critical vulnerability stops a release before the image is copied to
`release`. Only images in `release` are signed, and the cluster runs only signed images, so the
stopped build can't run in the cluster, even if someone deploys it from `candidate` by hand.

## 20. Check the cluster refuses an unsigned image

Try to start a pod with the image of your **latest build**, taken from `candidate`. It is the
same image (same digest) as release `1.1.1`, but only the copy in `release` is signed, and the
cluster trusts only that repository. The test pod
([verify/admission-test-pod.yaml](../verify/admission-test-pod.yaml)) follows every other rule,
so the image is the only difference. `--dry-run=server` runs every admission check and creates
nothing.

```bash
cd ~/k8slab01/cloud-infra-labs/labs/kubernetes/01-eks-gitops-image-scanning-signing
REGISTRY="$(aws sts get-caller-identity --query Account --output text).dkr.ecr.ap-northeast-1.amazonaws.com"
digest_of() { aws ecr describe-images --repository-name "$1" --image-ids imageTag="$2" --query 'imageDetails[0].imageDigest' --output text; }
CANDIDATE="$REGISTRY/k8slab01-dev/candidate/sample-web-app@$(digest_of k8slab01-dev/candidate/sample-web-app "$(git -C ~/k8slab01/sample-web-app rev-parse HEAD)")"
RELEASED="$REGISTRY/k8slab01-dev/release/sample-web-app:1.1.1@$(digest_of k8slab01-dev/release/sample-web-app 1.1.1)"

sed "s|IMAGE|$CANDIDATE|" verify/admission-test-pod.yaml | kubectl apply --dry-run=server -f -
```

Expected: `Error from server (Forbidden): error when creating "STDIN": admission webhook
"validation.gatekeeper.sh" denied the request:`, followed by `[only-our-release-repository]`
(wrong repository) and `[signed-by-our-signer-profile]` (Ratify found no valid signature).

Now the same pod with the released image:

```bash
sed "s|IMAGE|$RELEASED|" verify/admission-test-pod.yaml | kubectl apply --dry-run=server -f -
```

Expected: `pod/admission-test created (server dry run)`: the rules let a signed release in.

## 21. Check the cluster refuses an unsafe pod

`kubectl run` makes a pod with no security settings: it would run as root, keep all Linux
capabilities, and allow privilege escalation. Kubernetes' built-in Pod Security Admission
(level `restricted` on `app-dev`) refuses it, even with a signed image:

```bash
kubectl -n app-dev run root-test --image="$RELEASED" --dry-run=server
```

Expected: `Error from server (Forbidden): pods "root-test" is forbidden: violates PodSecurity
"restricted:v1.36":`, followed by what is missing (`allowPrivilegeEscalation != false`,
`unrestricted capabilities`, `runAsNonRoot != true`, `seccompProfile`).

## 22. Lose a pod and keep serving

The app runs two pods, one per Availability Zone, behind the load balancer.

**Via CLI:** check where they run:

```bash
kubectl -n app-dev get pods -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName,STATUS:.status.phase
kubectl get nodes -L topology.kubernetes.io/zone
```

Expected: two pods on two different nodes, and those nodes in `ap-northeast-1a` and
`ap-northeast-1c`.

Watch the app while you delete one pod. **Via browser:** reload `<app_url>/` every few seconds.
**Via CLI (more exact):** in a second terminal (with `APP_URL` set):

```bash
while true; do echo "$(date +%T) $(curl -s -o /dev/null -w '%{http_code}' "$APP_URL/items")"; sleep 1; done
```

It prints one HTTP status per second; `200` means the app answered. In the first terminal:

```bash
kubectl -n app-dev delete pod "$(kubectl -n app-dev get pods -l app.kubernetes.io/name=sample-web-app -o jsonpath='{.items[0].metadata.name}')"
kubectl -n app-dev get pods -w
```

Expected: the page keeps loading and the loop keeps printing `200` (a single `502` can appear
while the load balancer stops sending to the deleted pod). Within about a minute a new pod is
`Running` and `1/1` ready. Press `Ctrl+C` to stop `-w` and the loop.

## 23. Watch Argo CD undo a change made by hand

Delete something Argo CD manages, the app's PodDisruptionBudget, as if someone changed the
cluster by hand:

```bash
kubectl -n app-dev delete pdb sample-web-app
sleep 30
kubectl -n app-dev get pdb sample-web-app
```

Expected: the PodDisruptionBudget is back, with an `AGE` of a few seconds: Argo CD's self-heal
put it back to match Git.

**Via browser:** the Argo CD UI → **sample-web-app** → **History and rollback** or the resource
tree: the `sample-web-app` PodDisruptionBudget is there again and the app is **Synced**.

## 24. Roll back to the previous version

A rollback is a pull request in `eks-platform-gitops` that sets the previous version back. The
previous image is still in `release`, already scanned and signed, so nothing is rebuilt.
Reverting the `1.1.1` deployment brings back `1.0.0`. It changes only dev's overlay, so it needs
no review.

**Via browser:** `eks-platform-gitops` → **Pull requests** → **Closed** → **Deploy
sample-web-app 1.1.1 to dev** → **Revert** → **Create pull request** → **Squash and merge** →
**Confirm**.

**Via CLI:**

```bash
cd ~/k8slab01/eks-platform-gitops
git switch main && git pull
git switch -c rollback-dev-1.0.0
git revert --no-edit "$(git log -1 --format=%H -i --grep='sample-web-app 1.1.1' -- manifests/sample-web-app/overlays/dev)"
git push origin rollback-dev-1.0.0
gh pr create --fill --base main
gh pr merge --squash --delete-branch
```

Check (Argo CD deploys it within about 3 minutes; the `annotate` line makes it check Git now):

```bash
kubectl -n argocd annotate application sample-web-app argocd.argoproj.io/refresh=normal --overwrite
sleep 60
curl -s "$APP_URL/info"; echo
```

Expected: `"version":"1.0.0"`, and the page shows `sample-web-app · 1.0.0` after a reload. The
pods are replaced one at a time, so the app keeps answering during the rollback.

Next: [Part 5 — Clean up →](5-clean-up.md)
