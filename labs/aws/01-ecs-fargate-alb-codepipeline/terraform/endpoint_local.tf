# Names and settings for the VPC endpoints. The tasks have no internet route, so these are
# their only way to reach AWS services.

locals {
  vpc_endpoints = {
    # Interface endpoints: private IPs in the app subnets, private DNS on
    ecr-api        = { service = "ecr.api", type = "Interface", name = "${local.name_prefix}-vpce-ecr-api" }               # image metadata, login
    ecr-dkr        = { service = "ecr.dkr", type = "Interface", name = "${local.name_prefix}-vpce-ecr-dkr" }               # image pulls
    secretsmanager = { service = "secretsmanager", type = "Interface", name = "${local.name_prefix}-vpce-secretsmanager" } # DB password
    logs           = { service = "logs", type = "Interface", name = "${local.name_prefix}-vpce-logs" }                     # container logs

    # Gateway endpoint: a route in the private route table; free. ECR stores image layers in S3.
    s3 = { service = "s3", type = "Gateway", name = "${local.name_prefix}-vpce-s3" }
  }
}
