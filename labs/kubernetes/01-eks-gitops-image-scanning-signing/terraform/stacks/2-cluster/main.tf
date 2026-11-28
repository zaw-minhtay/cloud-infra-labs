# EKS cluster with one managed node group, in the private subnets.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.30.2"

  name               = local.name
  kubernetes_version = var.kubernetes_version

  vpc_id     = data.aws_vpc.this.id
  subnet_ids = data.aws_subnets.private.ids

  # Kubernetes API: private for the nodes, public only for your IP address. CI never calls it:
  # it only writes to Git, and Argo CD pulls from inside the cluster.
  endpoint_private_access      = true
  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.admin_cidrs

  # Access through EKS access entries only (no aws-auth ConfigMap). Whoever runs this stack
  # becomes cluster admin.
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  # Control-plane logs are charged per GB in CloudWatch: off in the lab.
  enabled_log_types           = []
  create_cloudwatch_log_group = false

  # Kubernetes secrets are encrypted with a KMS key that the module creates (its default).

  addons = {
    # Gives every pod a VPC address, and enforces Kubernetes NetworkPolicies.
    vpc-cni = {
      before_compute = true
      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
      })
    }
    # Hands short-lived AWS credentials to pods (EKS Pod Identity).
    eks-pod-identity-agent = {
      before_compute = true
    }
    coredns    = {}
    kube-proxy = {}
    aws-ebs-csi-driver = {
      pod_identity_association = [{
        role_arn        = module.ebs_csi_pod_identity.iam_role_arn
        service_account = "ebs-csi-controller-sa"
      }]
    }
  }

  eks_managed_node_groups = {
    default = {
      name           = "${local.name}-default"
      instance_types = var.node_instance_types
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
      # The module's defaults are kept: Amazon Linux 2023, and IMDSv2 with a hop limit of 1,
      # so pods can't use the node's IAM role.
    }
  }
}

# IAM role for the EBS CSI driver add-on, given to its service account through Pod Identity.
module "ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.11.0"

  name                      = "${local.name}-ebs-csi"
  attach_aws_ebs_csi_policy = true
}
