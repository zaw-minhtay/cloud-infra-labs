# Part 4 — Verify (steps 16–21)

[← Part 3](3-pipeline.md) · [Guide index](../SETUP.md) · Next: [Part 5 — Clean up →](5-clean-up.md)

Prove each design goal: high availability, no internet route, failure recovery, and safe
deployments. Run the CLI commands from the `terraform/` folder with `AWS_PROFILE` set and
`APP_URL` from step 14.

In steps 18–20 you break something and watch that the app keeps answering. Keep one of these
open while you do:

**Via browser:** `<app_url>/`. Reload it every few seconds: the table should keep loading. When
the app can't reach the database, the page shows `storage unavailable, try again` in red.

**Via CLI (more exact):** a second terminal (with `AWS_PROFILE` and `APP_URL` set) running this
watch loop:

```bash
while true; do echo "$(date +%T) $(curl -s -o /dev/null -w '%{http_code}' $APP_URL/items)"; sleep 1; done
```

It prints one HTTP status per second: `200` means the app answered. Press `Ctrl+C` to stop it.

## 16. Check the tasks run in two Availability Zones

**Via console:** **ECS** → **Clusters** → **awslab01-dev-cluster** → **awslab01-dev-service-app**
→ **Tasks** tab. Open each task to see its Availability Zone. Expected: two tasks, both
**Running**, one in `ap-northeast-1a` and one in `ap-northeast-1c`.

**Via CLI:**

```bash
TASKS=$(aws ecs list-tasks --cluster awslab01-dev-cluster --service-name awslab01-dev-service-app --query "taskArns" --output text)
aws ecs describe-tasks --cluster awslab01-dev-cluster --tasks $TASKS \
  --query "tasks[].[availabilityZone,lastStatus]" --output text
```

Expected: one task in `ap-northeast-1a` and one in `ap-northeast-1c`, both `RUNNING`.

## 17. Check the app and database have no internet route

**Via console:** **VPC** → **Route tables** → select **awslab01-dev-rtb-private** and look at
its routes. Expected: exactly two routes, `10.0.0.0/16` → `local` (inside the VPC) and a `pl-…`
prefix list → a `vpce-…` (the S3 gateway endpoint). **No `0.0.0.0/0` route**: the private
subnets can't reach the internet.

**Via CLI:**

```bash
aws ec2 describe-route-tables --filters Name=tag:Name,Values=awslab01-dev-rtb-private \
  --query "RouteTables[0].Routes[].[DestinationCidrBlock || DestinationPrefixListId, GatewayId]" --output text
```

Expected: the same two routes, `10.0.0.0/16 local` and `pl-… vpce-…`, and no `0.0.0.0/0`.

## 18. Survive a task failure

With the browser page or the watch loop open, stop one task:

**Via console:** **ECS** → **Clusters** → **awslab01-dev-cluster** → **awslab01-dev-service-app**
→ **Tasks** tab → select **one** task → **Stop** → **Stop selected**, and confirm.

**Via CLI:**

```bash
TASK=$(aws ecs list-tasks --cluster awslab01-dev-cluster --service-name awslab01-dev-service-app --query "taskArns[0]" --output text)
aws ecs stop-task --cluster awslab01-dev-cluster --task "$TASK" --reason "HA test" --query "task.lastStatus" --output text
```

Expected: the page keeps loading and the watch loop keeps printing **`200`**, because the ALB
sends everything to the other task. Within 1–2 minutes ECS starts a replacement; repeat step 16
to see two tasks again.

## 19. Survive an Aurora failover

With the browser page or the watch loop open, make the reader (AZ c) the new writer:

**Via console:** **RDS** → **Databases** → select the cluster **awslab01-dev-aurora** →
**Actions** → **Failover**, and confirm. The cluster has one reader, `awslab01-dev-aurora-1c`,
so that one becomes the writer.

**Via CLI:**

```bash
aws rds failover-db-cluster --db-cluster-identifier awslab01-dev-aurora \
  --target-db-instance-identifier awslab01-dev-aurora-1c --query "DBCluster.Status" --output text
```

Expected: for a short time (usually under a minute) the page shows `storage unavailable, try
again` and the watch loop prints **`503`**; then the table loads and the loop prints **`200`**
again. The app reconnects to the new writer by itself, and the tasks stay healthy the whole time,
because `/healthz` doesn't depend on the database. Check the roles have swapped:

**Via console:** **RDS** → **Databases** → **awslab01-dev-aurora**. Expected: the role next to
each instance has swapped, and `awslab01-dev-aurora-1c` is now the writer.

**Via CLI:**

```bash
aws rds describe-db-clusters --db-cluster-identifier awslab01-dev-aurora \
  --query "DBClusters[0].DBClusterMembers[].[DBInstanceIdentifier,IsClusterWriter]" --output text
```

Expected: `awslab01-dev-aurora-1c True` and `awslab01-dev-aurora-1a False`.

Your items are still there: reload `<app_url>/` (or `curl -s $APP_URL/items`).

## 20. Check a broken release is rolled back automatically

Deploy a version that passes the tests but can't serve traffic: it listens on the wrong port, so
the ALB health checks fail. Commit and push it (git, CLI only):

```bash
cd ..
sed -i '' 's/^server.port=8080/server.port=9090/' app/src/main/resources/application.properties
git add app/src/main/resources/application.properties
git commit -m "test(aws): break the app port on purpose"
git push
cd terraform
```

Expected, over about 15 minutes:
- The pipeline's **Build** succeeds (the tests still pass), then **Deploy** fails.
- ECS starts new tasks, they fail their health checks, and the **deployment circuit breaker**
  rolls the service back to the previous task definition.
- The page keeps loading and the watch loop keeps printing **`200`** throughout: one old task is
  always serving.

Check the pipeline and the rollback:

**Via console:**
- **CodePipeline** → **awslab01-dev-pipeline**. Expected: **Source** and **Build** **Succeeded**,
  **Deploy** **Failed**.
- **ECS** → **Clusters** → **awslab01-dev-cluster** → **awslab01-dev-service-app** → **Events**
  tab. Expected: a message about the deployment failing and rolling back (`circuit breaker`)
  near the top.

**Via CLI:**

```bash
aws codepipeline get-pipeline-state --name awslab01-dev-pipeline \
  --query "stageStates[].[stageName,latestExecution.status]" --output table
aws ecs describe-services --cluster awslab01-dev-cluster --services awslab01-dev-service-app \
  --query "services[0].events[0:5].message" --output text
```

Expected: `Source` and `Build` `Succeeded`, `Deploy` `Failed`, and a `circuit breaker` rollback
message.

Then undo the broken commit so `main` is healthy again; the pipeline deploys it (git, CLI only):

```bash
cd ..
git revert --no-edit HEAD
git push
cd terraform
```

## 21. Check the alarms exist

**Via console:** **CloudWatch** → **Alarms**, then search for `awslab01-dev-`. Expected: five
alarms, `awslab01-dev-alb-5xx`, `awslab01-dev-alb-unhealthy-hosts`, `awslab01-dev-ecs-cpu-high`,
`awslab01-dev-aurora-cpu-high`, `awslab01-dev-aurora-connections-high`, mostly **OK**.
`awslab01-dev-alb-unhealthy-hosts` may show **In alarm** for a while after steps 18–20: that is
the alarm doing its job.

**Via CLI:**

```bash
aws cloudwatch describe-alarms --alarm-name-prefix awslab01-dev- \
  --query "MetricAlarms[].[AlarmName,StateValue]" --output text
```

Expected: the same five alarms, mostly `OK` (or `ALARM` for the unhealthy-hosts alarm, as above).

Next: [Part 5 — Clean up →](5-clean-up.md)
