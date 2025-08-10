# /terraform/variables.tf

variable "aws_region" {
  description = "The AWS region to deploy the resources in."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "The name for the EKS cluster."
  type        = string
  default     = "openwebui-cluster"
}

variable "instance_type" {
  description = "The EC2 instance type for the EKS worker nodes."
  type        = string
  default     = "m5.large"
}