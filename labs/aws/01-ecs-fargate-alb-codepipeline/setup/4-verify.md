# Part 4 — Verify (steps 16–21)

[← Part 3](3-pipeline.md) · [Guide index](../SETUP.md) · Next: [Part 5 — Clean up →](5-clean-up.md)

Prove each design goal: high availability, no internet route, failure recovery, and safe
deployments. Run from the `terraform/` folder with `AWS_PROFILE` set and `APP_URL` from step 14.

Steps 18–20 are easiest with **two terminals**: one watching the app, one breaking things. In the
watching terminal (with `AWS_PROFILE` and `APP_URL` set), run:

```bash
while true; do echo "$(date +%T) $(curl -s -o /dev/null -w '%{http_code}' $APP_URL/items)"; sleep 1; done
```

It prints one HTTP status per second: `200` means the app answered. Press `Ctrl+C` to stop it.

## 16. Check the tasks run in two Availability Zones

```bash
TASKS=$(aws ecs list-tasks --cluster awslab01-dev-cluster --service-name awslab01-dev-service-app --query "taskArns" --output text)
aws ecs describe-tasks --cluster awslab01-dev-cluster --tasks $TASKS \
  --query "tasks[].[availabilityZone,lastStatus]" --output text
```

Expected: one task in `ap-northeast-1a` and one in `ap-northeast-1c`, both `RUNNING`.

## 17. Check the app and database have no internet route

```bash
aws ec2 describe-route-tables --filters Name=tag:Name,Values=awslab01-dev-rtb-private \
  --query "RouteTables[0].Routes[].[DestinationCidrBlock || DestinationPrefixListId, GatewayId]" --output text
```

Expected: exactly two routes, `10.0.0.0/16 local` (inside the VPC) and a `pl-…` prefix list to a
`vpce-…` (the S3 gateway endpoint). **No `0.0.0.0/0` route**: the private subnets can't reach
the internet.

## 18. Survive a task failure

With the watch loop running, stop one task:

```bash
TASK=$(aws ecs list-tasks --cluster awslab01-dev-cluster --service-name awslab01-dev-service-app --query "taskArns[0]" --output text)
aws ecs stop-task --cluster awslab01-dev-cluster --task "$TASK" --reason "HA test" --query "task.lastStatus" --output text
```

Expected: the watch loop keeps printing **`200`**, because the ALB sends everything to the other
task. Within 1–2 minutes ECS starts a replacement; repeat step 16 to see two tasks again.

## 19. Survive an Aurora failover

With the watch loop running, make the reader (AZ c) the new writer:

```bash
aws rds failover-db-cluster --db-cluster-identifier awslab01-dev-aurora \
  --target-db-instance-identifier awslab01-dev-aurora-1c --query "DBCluster.Status" --output text
```

Expected: the watch loop shows a short run of **`503`** (usually under a minute), then **`200`**
again. The app reconnects to the new writer by itself, and the tasks stay healthy the whole time,
because `/healthz` doesn't depend on the database. Check the roles have swapped:

```bash
aws rds describe-db-clusters --db-cluster-identifier awslab01-dev-aurora \
  --query "DBClusters[0].DBClusterMembers[].[DBInstanceIdentifier,IsClusterWriter]" --output text
```

Expected: `awslab01-dev-aurora-1c True` and `awslab01-dev-aurora-1a False`. Your items are still there:
`curl -s $APP_URL/items`.

## 20. Check a broken release is rolled back automatically

Deploy a version that passes the tests but can't serve traffic: it listens on the wrong port, so
the ALB health checks fail.

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
- The watch loop keeps printing **`200`** throughout: one old task is always serving.

Check the rollback in the service events:

```bash
aws ecs describe-services --cluster awslab01-dev-cluster --services awslab01-dev-service-app \
  --query "services[0].events[0:5].message" --output text
```

Expected: a message about the deployment failing and rolling back (`circuit breaker`).
Then undo the broken commit so `main` is healthy again (the pipeline deploys it):

```bash
cd ..
git revert --no-edit HEAD
git push
cd terraform
```

## 21. Check the alarms exist

```bash
aws cloudwatch describe-alarms --alarm-name-prefix awslab01-dev- \
  --query "MetricAlarms[].[AlarmName,StateValue]" --output text
```

Expected: five alarms, `awslab01-dev-alb-5xx`, `awslab01-dev-alb-unhealthy-hosts`,
`awslab01-dev-ecs-cpu-high`, `awslab01-dev-aurora-cpu-high`, `awslab01-dev-aurora-connections-high`,
mostly `OK`. `awslab01-dev-alb-unhealthy-hosts` may show `ALARM` for a while after steps 18–20:
that is the alarm doing its job.

Next: [Part 5 — Clean up →](5-clean-up.md)
