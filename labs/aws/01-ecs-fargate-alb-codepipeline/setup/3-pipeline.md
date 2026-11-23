# Part 3 — Pipeline (steps 11–15)

[← Part 2](2-infrastructure.md) · [Guide index](../SETUP.md) · Next: [Part 4 — Verify →](4-verify.md)

Connect GitHub, build the first image, start the two tasks, and use the API. Run every command
from the `terraform/` folder, in a terminal where `AWS_PROFILE` is set (step 2).

## 11. Finish the GitHub connection

Terraform created the connection `awslab01-dev-github`, but only you can approve it. This installs
the **AWS Connector for GitHub** app on your repository:

1. Open the AWS console → **Developer Tools** → **Settings** → **Connections**
   (region **Asia Pacific (Tokyo)**).
2. Click **awslab01-dev-github** (status **Pending**) → **Update pending connection**.
3. In the pop-up, click **Install a new app**. On GitHub, choose your account, select **Only
   select repositories** → `cloud-infra-labs`, and click **Install**.
4. Back in the pop-up, click **Connect**.

Check:

```bash
aws codeconnections list-connections --query "Connections[?ConnectionName=='awslab01-dev-github'].ConnectionStatus" --output text
```

Expected: `AVAILABLE`.

## 12. Run the pipeline for the first time

```bash
aws codepipeline start-pipeline-execution --name awslab01-dev-pipeline
```

Watch it in the console: **CodePipeline** → **awslab01-dev-pipeline**. It runs three stages:
**Source** (GitHub) → **Build** (CodeBuild: tests, image, push to ECR) → **Deploy** (ECS). The
build takes about 5–10 minutes. Or check from the terminal:

```bash
aws codepipeline get-pipeline-state --name awslab01-dev-pipeline \
  --query "stageStates[].[stageName,latestExecution.status]" --output table
```

Expected: all three stages `Succeeded`. The image is now in ECR, tagged with the commit ID:

```bash
aws ecr describe-images --repository-name awslab01-dev-app --query "imageDetails[].imageTags" --output text
```

Expected: one 7-character tag, e.g. `1a2b3c4`.

## 13. Start the two tasks

Apply again without the override. `app_desired_count` goes back to **2** (from
`env/dev/terraform.tfvars`):

```bash
terraform apply -var-file=env/dev/terraform.tfvars
```

Expected: `Plan: 0 to add, 1 to change, 0 to destroy.` (only the service's desired count). Type
`yes`. Terraform does not touch the task definition the pipeline deployed: the service ignores
`task_definition` changes on purpose.

Wait until both tasks run and pass the ALB health check (about 2–3 minutes):

```bash
aws ecs wait services-stable --cluster awslab01-dev-cluster --services awslab01-dev-service-app
TG_ARN=$(aws elbv2 describe-target-groups --names awslab01-dev-tg-app --query "TargetGroups[0].TargetGroupArn" --output text)
aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --query "TargetHealthDescriptions[].TargetHealth.State" --output text
```

Expected: the `wait` returns with no output, then `healthy healthy`.

## 14. Use the API

```bash
APP_URL=$(terraform output -raw app_url)
curl -s $APP_URL/
curl -s -X POST $APP_URL/items -H 'Content-Type: application/json' -d '{"name":"Book","description":"Read later"}'
curl -s -X POST $APP_URL/items -H 'Content-Type: application/json' -d '{"name":"Pen"}'
curl -s $APP_URL/items
curl -s -X PUT $APP_URL/items/1 -H 'Content-Type: application/json' -d '{"name":"Book","description":"Finished"}'
curl -s $APP_URL/items/1
```

Expected:
```
{"version":"<commit-id>","app":"items-api"}
{"id":1,"name":"Book","description":"Read later","updatedAt":"…"}
{"id":2,"name":"Pen","description":"","updatedAt":"…"}
[{"id":1,…},{"id":2,…}]
{"id":1,"name":"Book","description":"Finished","updatedAt":"…"}
{"id":1,"name":"Book","description":"Finished","updatedAt":"…"}
```

The data is in Aurora, so it survives task restarts and deployments (you'll see that next).

## 15. Deploy a change through the pipeline

Change the app's name in the response, commit **only that file**, and push:

```bash
cd ..
sed -i '' 's/"app", "items-api"/"app", "items-api-v2"/' app/src/main/java/com/example/items/ItemController.java
git add app/src/main/java/com/example/items/ItemController.java
git commit -m "feat(aws): rename app in the info response"
git push
```

The push starts the pipeline automatically (it watches `app/**` on `main`). Watch it in the
console, or:

```bash
cd terraform
aws codepipeline get-pipeline-state --name awslab01-dev-pipeline \
  --query "stageStates[].[stageName,latestExecution.status]" --output table
```

When all stages are `Succeeded` (about 10 minutes; ECS replaces the tasks one at a time):

```bash
curl -s $APP_URL/
curl -s $APP_URL/items
```

Expected: `{"version":"<new-commit-id>","app":"items-api-v2"}`, and **both items from step 14
are still there**: the data lives in Aurora, not in the tasks.

Next: [Part 4 — Verify →](4-verify.md)
