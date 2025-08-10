# /terraform/auth.tf

# This resource takes full control of the aws-auth configmap.
# It builds the entire map from scratch, ensuring both the worker nodes
# and your admin role have the correct permissions.
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
    # This label tells Kubernetes that Terraform is managing this resource.
    labels = {
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }

  # We construct the data block without reading the existing map first.
  data = {
    "mapRoles" = yamlencode([
      # Block 1: This adds the worker nodes so they can join the cluster.
      {
        rolearn  = module.eks.eks_managed_node_groups["main"].iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      # Block 2: This adds your IAM role as a cluster administrator.
      {
        rolearn  = data.aws_caller_identity.current.arn
        username = "admin"
        groups   = ["system:masters"]
      }
    ])
  }

  # This ensures the cluster exists before we try to create the configmap.
  depends_on = [
    module.eks.cluster_id
  ]
}