locals {
  # Naming rule: {project}-{env}[-{purpose}][-{az}], e.g. k8slab01-dev, k8slab01-dev-private-1a
  name = "${var.project}-${var.env}"

  # "ap-northeast-1a" -> "1a", the last part of per-AZ names
  az_suffix = [for az in var.azs : substr(az, length(az) - 2, 2)]

  tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
    Stack       = "network"
  }
}
