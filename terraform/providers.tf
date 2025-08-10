# /terraform/providers.tf

# This data source retrieves a temporary authentication token for the EKS cluster.
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# The Kubernetes provider uses the cluster details from the EKS module
# and the token from the data source above to authenticate.
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# The Helm provider is configured to use the Kubernetes provider's settings.
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}