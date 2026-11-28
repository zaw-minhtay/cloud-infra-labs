# Part 1 — Prepare (steps 1–5)

[← Guide index](../SETUP.md) · Next: [Part 2 — Infrastructure →](2-infrastructure.md)

Install the tools, connect to your AWS account, and check the app works on your machine. Nothing
in this part costs money.

## 1. Install the tools

Install [Homebrew](https://brew.sh) first if `brew --version` doesn't work. Then:

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform awscli
```

**git** comes with Apple's Command Line Tools: if `git --version` says it's missing, click
**Install** when macOS asks (or run `xcode-select --install`).

Check:

```bash
terraform version
aws --version
git --version
```

Expected: `Terraform v1.17.x` or later, `aws-cli/2.x`, and a git version.

Already have Terraform from Homebrew? Update it with `brew upgrade hashicorp/tap/terraform`.

## 2. Connect the AWS CLI to your dev account

Use any sign-in method your account supports, for example IAM Identity Center
(`aws configure sso`) or `aws login`. Name the profile so you can recognise it, then make it the
default for this terminal:

```bash
export AWS_PROFILE=<your-dev-profile>
aws sts get-caller-identity
```

Expected: a JSON block whose `"Account"` is your **dev** account ID (12 digits). Every later
step runs in a terminal where `AWS_PROFILE` is set like this.

To compare with the console: sign in to the AWS console with the same account and open the
account menu at the top right. Expected: its **Account ID** is the same 12 digits.

> Each environment (dev, stg, prd) is meant to live in its **own AWS account**. No file in this
> lab holds an account ID: Terraform builds in whichever account this login points at, so check
> the `"Account"` above before every Terraform step.

## 3. Get your own copy of this repo

CodePipeline will read **your** repository, so you need your own copy:

1. On GitHub, click **Fork** on this repository.
2. Clone your fork and go to the lab folder:

```bash
git clone https://github.com/<your-github-username>/cloud-infra-labs.git
cd cloud-infra-labs/labs/aws/01-ecs-fargate-alb-codepipeline
```

All commands in this guide run from this lab folder unless a step says otherwise.

## 4. Build and test the app locally (optional)

Files in [app/](../app/): a Java 25 Spring Boot REST API with a small web page
([pom.xml](../app/pom.xml), [src/](../app/src/)), and a [Dockerfile](../app/Dockerfile) that
builds it with Maven on Amazon Corretto 25 and runs it on Corretto 25. Building the image also
runs the unit tests:

```bash
docker build --build-arg APP_VERSION=local -t items-api:local app/
```

Expected (near the end): `Tests run: 8, Failures: 0, Errors: 0, Skipped: 0`, then
`BUILD SUCCESS`, then the image is created. The first build downloads the base images and Maven
dependencies, so it takes a few minutes.

## 5. Run the app against MySQL on your machine (optional)

Start a temporary MySQL 8.0 (the version Aurora MySQL 3 is compatible with) and the app, side
by side on their own Docker network:

```bash
docker network create items-net
docker run -d --name items-mysql --network items-net \
  -e MYSQL_ROOT_PASSWORD=localpass -e MYSQL_DATABASE=appdb \
  public.ecr.aws/docker/library/mysql:8.0
```

Wait about 30 seconds for MySQL to start, then start the app:

```bash
docker run -d --name items-app --network items-net -p 8085:8080 \
  -e DB_HOST=items-mysql -e DB_USER=root -e DB_PASSWORD=localpass \
  items-api:local
```

After about 15 seconds, try the app. Use **either** the browser or the CLI, not both: each
creates the same item, and the expected output assumes the database is still empty.

**Via browser:** open http://localhost:8085/. Expected: the **Items** page, with
`items-api · local` at the top and "No items yet" in the table. Then:

1. Type **Book** as the name and **Read later** as the description, and click **Add**.
2. Click **Edit** on **Book**, change the description to **Finished**, and click **Save**.

Expected: the table shows `1 Book Finished`, with the time it was last updated.

**Via CLI:** the page calls the REST API; `curl` calls the same endpoints directly:

```bash
curl -s localhost:8085/info
curl -s -X POST localhost:8085/items -H 'Content-Type: application/json' -d '{"name":"Book","description":"Read later"}'
curl -s localhost:8085/items
curl -s -X PUT localhost:8085/items/1 -H 'Content-Type: application/json' -d '{"name":"Book","description":"Finished"}'
curl -s localhost:8085/items/1
```

Expected:
```
{"version":"local","app":"items-api"}
{"id":1,"name":"Book","description":"Read later","updatedAt":"…"}
[{"id":1,"name":"Book","description":"Read later","updatedAt":"…"}]
{"id":1,"name":"Book","description":"Finished","updatedAt":"…"}
{"id":1,"name":"Book","description":"Finished","updatedAt":"…"}
```

Clean up the local containers:

```bash
docker rm -f items-app items-mysql
docker network rm items-net
```

Next: [Part 2 — Infrastructure →](2-infrastructure.md)
