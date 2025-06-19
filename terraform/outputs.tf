# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ips" {
  description = "Elastic IPs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ips
}

# EKS Outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks.cluster_version
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if enabled"
  value       = module.eks.oidc_provider_arn
}

# Node Group Outputs
output "node_groups" {
  description = "Map of attribute maps for all EKS node groups"
  value       = module.eks.node_groups
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = module.eks.node_security_group_id
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "ARNs of the ECR repositories"
  value       = module.ecr.repository_arns
}

# Load Balancer Outputs
output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = var.enable_load_balancer ? module.alb[0].dns_name : null
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = var.enable_load_balancer ? module.alb[0].arn : null
}

output "load_balancer_zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = var.enable_load_balancer ? module.alb[0].zone_id : null
}

# IAM Outputs
output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "node_groups_iam_role_arn" {
  description = "IAM role ARNs of the EKS node groups"
  value       = module.eks.node_groups_iam_role_arn
}

# Application Outputs
output "application_url" {
  description = "URL to access the application"
  value = var.domain_name != "" ? (
    var.certificate_arn != "" ? "https://${var.domain_name}" : "http://${var.domain_name}"
  ) : (
    var.enable_load_balancer ? "http://${module.alb[0].dns_name}" : "kubectl port-forward required"
  )
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# Environment Information
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

# Monitoring Outputs (when enabled)
output "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring"
  value       = var.enable_monitoring ? var.monitoring_namespace : null
}

# Resource Tags
output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
} 