# Part 3 — Pipeline (steps 11–15)

[← Part 2](2-infrastructure.md) · [Guide index](../SETUP.md) · Next: [Part 4 — Verify →](4-verify.md)

Connect GitHub, build the first image, start the two tasks, and use the app. Run every command
from the `terraform/` folder, in a terminal where `AWS_PROFILE` is set (step 2).

## 11. Finish the GitHub connection

Terraform created the connection `awslab01-dev-github`, but only you can approve it, and only in
the console. This installs the **AWS Connector for GitHub** app on your repository:

1. Open the AWS console → **Developer Tools** → **Settings** → **Connections**
   (region **Asia Pacific (Tokyo)**).
2. Click **awslab01-dev-github** (status **Pending**) → **Update pending connection**.
3. In the pop-up, click **Install a new app**. On GitHub, choose your account, select **Only
   select repositories** → `cloud-infra-labs`, and click **Install**.
4. Back in the pop-up, click **Connect**.

Check the connection:

**Via console:** on the same **Connections** page, **awslab01-dev-github** now shows status
**Available**.

**Via CLI:**

```bash
aws codeconnections list-connections --query "Connections[?ConnectionName=='awslab01-dev-github'].ConnectionStatus" --output text
```

Expected: `AVAILABLE`.

## 12. Run the pipeline for the first time

Start the pipeline:

**Via console:** **CodePipeline** → **awslab01-dev-pipeline** → **Release change** →
**Release**.

**Via CLI:**

```bash
aws codepipeline start-pipeline-execution --name awslab01-dev-pipeline
```

It runs three stages: **Source** (GitHub) → **Build** (CodeBuild: tests, image, push to ECR) →
**Deploy** (ECS). The build takes about 5–10 minutes. Check the stages:

**Via console:** the same **awslab01-dev-pipeline** page. Expected: all three stages show
**Succeeded**.

**Via CLI:**

```bash
aws codepipeline get-pipeline-state --name awslab01-dev-pipeline \
  --query "stageStates[].[stageName,latestExecution.status]" --output table
```

Expected: all three stages `Succeeded`.

The image is now in ECR, tagged with the commit ID. Check it:

**Via console:** **ECR** → **Private registry** → **Repositories** → **awslab01-dev-app**. Open
the image to see its tag. Expected: one 7-character tag, e.g. `1a2b3c4`.

**Via CLI:**

```bash
aws ecr describe-images --repository-name awslab01-dev-app --query "imageDetails[].imageTags" --output text
```

Expected: the same 7-character tag.

## 13. Start the two tasks

Apply again without the override. `app_desired_count` goes back to **2** (from
`env/dev/terraform.tfvars`). CLI only:

```bash
terraform apply -var-file=env/dev/terraform.tfvars
```

Expected: `Plan: 0 to add, 1 to change, 0 to destroy.` (only the service's desired count). Type
`yes`. Terraform does not touch the task definition the pipeline deployed: the service ignores
`task_definition` changes on purpose.

Wait until both tasks run and pass the ALB health check (about 2–3 minutes):

**Via console:** **EC2** → **Load Balancing** → **Target Groups** → **awslab01-dev-tg-app** →
**Targets** tab. Expected: the **Status** column shows two targets, both `healthy` (reload the
page until they are).

**Via CLI:**

```bash
aws ecs wait services-stable --cluster awslab01-dev-cluster --services awslab01-dev-service-app
TG_ARN=$(aws elbv2 describe-target-groups --names awslab01-dev-tg-app --query "TargetGroups[0].TargetGroupArn" --output text)
aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --query "TargetHealthDescriptions[].TargetHealth.State" --output text
```

Expected: the `wait` returns with no output, then `healthy healthy`.

## 14. Use the app

Get the app's address from the console: **EC2** → **Load Balancers** → **awslab01-dev-alb** →
copy the **DNS name** (`awslab01-dev-alb-….ap-northeast-1.elb.amazonaws.com`). With `http://`
in front, this is the app's address; this guide calls it `<app_url>`.

Keep it in `APP_URL` for the CLI commands below and in later steps:

```bash
APP_URL=http://<paste-the-DNS-name>
```

> The ALB listens on plain HTTP (port 80). In the browser, type `http://`, not `https://`; the
> browser may show **Not secure**, which is expected here.

Create two items and update one. Use **either** the browser or the CLI, not both: each creates
the same two items.

**Via browser:** open `<app_url>/`. Expected: the **Items** page, with
`items-api · <commit-id>` at the top and "No items yet" in the table. Then:

1. Type **Book** as the name and **Read later** as the description, and click **Add**.
2. Type **Pen** as the name (no description), and click **Add**.
3. Click **Edit** on **Book**, change the description to **Finished**, and click **Save**.

Expected: the table shows `1 Book Finished` and `2 Pen`, each with the time it was last updated.

**Via CLI:** the page calls the REST API; `curl` calls the same endpoints directly:

```bash
curl -s -X POST $APP_URL/items -H 'Content-Type: application/json' -d '{"name":"Book","description":"Read later"}'
curl -s -X POST $APP_URL/items -H 'Content-Type: application/json' -d '{"name":"Pen"}'
curl -s -X PUT $APP_URL/items/1 -H 'Content-Type: application/json' -d '{"name":"Book","description":"Finished"}'
curl -s $APP_URL/items
curl -s $APP_URL/info
```

Expected:
```
{"id":1,"name":"Book","description":"Read later","updatedAt":"…"}
{"id":2,"name":"Pen","description":"","updatedAt":"…"}
{"id":1,"name":"Book","description":"Finished","updatedAt":"…"}
[{"id":1,"name":"Book","description":"Finished",…},{"id":2,"name":"Pen",…}]
{"version":"<commit-id>","app":"items-api"}
```

The data is in Aurora, so it survives task restarts and deployments (you'll see that next).

## 15. Deploy a change through the pipeline

Change the app's name in the response, commit **only that file**, and push (git, CLI only):

```bash
cd ..
sed -i '' 's/"app", "items-api"/"app", "items-api-v2"/' app/src/main/java/com/example/items/ItemController.java
git add app/src/main/java/com/example/items/ItemController.java
git commit -m "feat(aws): rename app in the info response"
git push
cd terraform
```

The push starts the pipeline automatically (it watches `app/**` on `main`). Check the stages
(about 10 minutes; ECS replaces the tasks one at a time):

**Via console:** **CodePipeline** → **awslab01-dev-pipeline**. Expected: a new run for your
commit, with all three stages **Succeeded**.

**Via CLI:**

```bash
aws codepipeline get-pipeline-state --name awslab01-dev-pipeline \
  --query "stageStates[].[stageName,latestExecution.status]" --output table
```

Expected: all three stages `Succeeded`.

Then check the new version is live:

**Via browser:** reload `<app_url>/`. Expected: `items-api-v2 · <new-commit-id>` at the top, and
**both items from step 14 are still in the table**: the data lives in Aurora, not in the tasks.

**Via CLI:**

```bash
curl -s $APP_URL/info
curl -s $APP_URL/items
```

Expected: `{"version":"<new-commit-id>","app":"items-api-v2"}`, and both items from step 14.

This change stays in your `main` until [step 27](5-clean-up.md#27-put-your-repository-back)
puts the name back.

Next: [Part 4 — Verify →](4-verify.md)
