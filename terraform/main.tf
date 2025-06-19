# Statista API Infrastructure - Main Root Module
# This file orchestrates all infrastructure modules for the Statista API

# Note: Terraform configuration and provider requirements are defined in versions.tf

# Provider Configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Note: Kubernetes and Helm providers are configured after EKS cluster creation
# They will be available through the module outputs

# Local Values
locals {
  cluster_name = "${var.project_name}-${var.environment}"
  
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    CreatedAt   = timestamp()
  })

  # Get availability zones if not provided
  azs = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available.names
}

# Data Sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name            = var.project_name
  environment            = var.environment
  vpc_cidr               = var.vpc_cidr
  availability_zones     = local.azs
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  
  tags = local.common_tags
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  project_name       = var.project_name
  environment        = var.environment
  repositories       = var.ecr_repositories
  lifecycle_policy   = var.ecr_lifecycle_policy
  
  tags = local.common_tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  project_name                            = var.project_name
  environment                            = var.environment
  cluster_name                           = local.cluster_name
  cluster_version                        = var.cluster_version
  
  vpc_id                                 = module.vpc.vpc_id
  private_subnet_ids                     = module.vpc.private_subnet_ids
  public_subnet_ids                      = module.vpc.public_subnet_ids
  
  cluster_endpoint_public_access         = var.cluster_endpoint_public_access
  cluster_endpoint_private_access        = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs   = var.cluster_endpoint_public_access_cidrs
  
  node_groups                            = var.node_groups
  
  tags = local.common_tags

  depends_on = [module.vpc]
}

# Application Load Balancer Module (Optional)
module "alb" {
  count  = var.enable_load_balancer ? 1 : 0
  source = "./modules/alb"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  certificate_arn    = var.certificate_arn
  
  tags = local.common_tags

  depends_on = [module.vpc]
}

# Monitoring Module (Optional)
module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"

  project_name        = var.project_name
  environment         = var.environment
  cluster_name        = module.eks.cluster_name
  monitoring_namespace = var.monitoring_namespace
  
  tags = local.common_tags

  depends_on = [module.eks]
}

# Configure Kubernetes provider after cluster creation
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}