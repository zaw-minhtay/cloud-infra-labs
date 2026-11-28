# State lives in the environment's S3 bucket (made by ../../bootstrap). The bucket name contains
# the account ID and the key names the environment, so both are passed to `terraform init`:
#   -backend-config="bucket=k8slab01-<env>-tfstate-<account-id>-ap-northeast-1"
#   -backend-config="key=<env>/cluster.tfstate"
terraform {
  backend "s3" {
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
