# /terraform/outputs.tf

output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster's API server."
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "A command to generate the kubeconfig file for the EKS cluster. This is used to create the GitHub secret."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
}