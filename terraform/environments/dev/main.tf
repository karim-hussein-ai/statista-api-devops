# Dev Environment Configuration
terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 Backend Configuration for remote state
  backend "s3" {
    bucket         = "statista-terraform-state-394256542096"
    key            = "dev/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "statista-terraform-locks"
  }
}

# Call the root module
module "statista_infrastructure" {
  source = "../.."

  # Environment Configuration
  environment    = "dev"
  project_name   = "statista-api"
  aws_region     = "eu-central-1"

  # VPC Configuration
  vpc_cidr               = "10.0.0.0/16"
  public_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs   = ["10.0.10.0/24", "10.0.11.0/24"]

  # EKS Configuration
  cluster_version = "1.32"
  node_groups = {
    general = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      capacity_type  = "ON_DEMAND"
      disk_size      = 20
      labels = {
        environment = "dev"
        nodegroup   = "general"
      }
      taints = []
      ami_type = "AL2023_x86_64"
    }
  }

  # Feature Flags
  enable_load_balancer = true
  enable_monitoring    = false

  # Tags
  tags = {
    Environment = "dev"
    Project     = "statista-api"
    ManagedBy   = "terraform"
    Owner       = "devops-team"
  }
}

# Outputs
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.statista_infrastructure.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.statista_infrastructure.cluster_endpoint
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = module.statista_infrastructure.kubectl_config_command
}

output "application_url" {
  description = "Application URL"
  value       = module.statista_infrastructure.application_url
}

output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.statista_infrastructure.ecr_repository_urls
} 