# main.tf

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.22"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Kubernetes provider must depend on EKS cluster being created
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token

  # Prevent "no such host" errors
  depends_on = [module.eks]
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }

  depends_on = [module.eks]
}

# Get authentication token for EKS
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  eks_managed_node_groups = {
    main = {
      name           = "main-node-group"
      instance_types = [var.instance_type]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }

  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }
}

# IAM Role for AWS Load Balancer Controller (IRSA)
module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.33.0"

  role_name = "aws-load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# Ensure kube-system namespace exists
resource "kubernetes_namespace" "kube_system" {
  metadata {
    name = "kube-system"
  }

  depends_on = [module.eks]
}

# Service Account for AWS Load Balancer Controller
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = kubernetes_namespace.kube_system.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.aws_load_balancer_controller_irsa_role.iam_role_arn
    }
  }

  depends_on = [module.eks, module.aws_load_balancer_controller_irsa_role]
}

# Install AWS Load Balancer Controller via Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.2"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  # Properly escaped annotation key for Terraform
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com\\/role-arn"
    value = module.aws_load_balancer_controller_irsa_role.iam_role_arn
  }

  depends_on = [
    module.eks,
    kubernetes_service_account.aws_load_balancer_controller,
    module.aws_load_balancer_controller_irsa_role
  ]
}
