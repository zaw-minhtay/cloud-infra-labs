locals {
  # Naming rule: {project}-{env}[-{purpose}], e.g. k8slab01-dev (the cluster), k8slab01-dev-ebs-csi
  name = "${var.project}-${var.env}"

  tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
    Stack       = "cluster"
  }
}
