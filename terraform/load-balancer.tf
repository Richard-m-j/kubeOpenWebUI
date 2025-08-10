# /terraform/load-balancer.tf

# This leverages an existing Terraform module to create the required IAM role
# that the Load Balancer Controller will use.
module "lb_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.0" # Use a specific version for stability

  role_name_prefix = "${var.cluster_name}-lb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# This resource uses the Helm provider to install the controller chart.
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2" # Specify a chart version compatible with K8s 1.32

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = "false" # We use the IAM role from the module above
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}