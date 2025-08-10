# /terraform/auth.tf

# This data source reads the existing aws-auth configmap created by the EKS module.
# This allows us to add our role without removing the existing node roles.
data "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  depends_on = [module.eks.cluster_id]
}

# This resource takes control of the aws-auth configmap data and adds your role.
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  force = true

  data = {
    # The 'try' function handles cases where mapRoles might not exist yet.
    # The 'yamldecode' function converts the YAML string to a list of maps.
    # The 'concat' function merges the existing list with our new list item.
    "mapRoles" = yamlencode(
      concat(
        try(yamldecode(data.kubernetes_config_map.aws_auth.data.mapRoles), []),
        [
          {
            rolearn  = data.aws_caller_identity.current.arn
            username = "admin"
            groups   = ["system:masters"]
          }
        ]
      )
    )
  }

  depends_on = [module.eks.cluster_id]
}