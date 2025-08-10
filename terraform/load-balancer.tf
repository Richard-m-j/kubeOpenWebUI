# /terraform/load-balancer.tf

# This uses a module to create a dedicated IAM role for the Load Balancer Controller.
module "iam_role_for_service_account" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.0"

  role_name_prefix = "${var.cluster_name}-lbc"
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
  version    = "1.7.2" # A known compatible version

  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    }
  ]
  
  # This ensures the controller's ServiceAccount is annotated with the IAM role ARN.
  set {
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam_role_for_service_account.iam_role_arn
  }
  
  depends_on = [
    kubernetes_config_map.aws_auth
  ]
}