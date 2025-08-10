# /terraform/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

# Creates a dedicated VPC, subnets, and related networking resources for the EKS cluster.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.3"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                  = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
  }
}

# Provisions the EKS cluster control plane and worker nodes.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
 version = "20.8.4"

  cluster_name = var.cluster_name
  # The cluster_version is intentionally removed to let the module choose the best version.
  # cluster_version = "1.32"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Disable the private endpoint to force all connections over the public endpoint
  cluster_endpoint_private_access = false

  # EKS Managed Node Group configuration
  eks_managed_node_groups = {
    main = {
      name           = "main-node-group"
      instance_types = [var.instance_type]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }

  # This security group rule is still good practice to keep
  cluster_security_group_additional_rules = {
    terraform_runner_https = {
      description = "Allow Terraform runner to access the EKS cluster API"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }


  # Installs essential drivers for storage and networking.
  # The EBS CSI Driver is required for the PersistentVolumeClaim.
  # The AWS Load Balancer Controller is required for the Ingress resource.
  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }
}