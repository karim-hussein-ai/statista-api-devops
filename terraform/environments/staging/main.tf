# Staging Environment Configuration
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
    key            = "staging/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "statista-terraform-locks"
  }
}

# Call the root module
module "statista_infrastructure" {
  source = "../.."

  # Environment Configuration
  environment    = "staging"
  project_name   = "statista-api"
  aws_region     = "eu-central-1"

  # VPC Configuration
  vpc_cidr               = "10.1.0.0/16"
  public_subnet_cidrs    = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs   = ["10.1.10.0/24", "10.1.11.0/24"]

  # EKS Configuration
  cluster_version = "1.28"
  node_groups = {
    general = {
      instance_types = ["t3.large"]
      min_size       = 2
      max_size       = 6
      desired_size   = 3
      capacity_type  = "ON_DEMAND"
      disk_size      = 30
      labels = {
        environment = "staging"
        nodegroup   = "general"
      }
      taints = []
    }
    spot = {
      instance_types = ["t3.large", "t3a.large"]
      min_size       = 0
      max_size       = 4
      desired_size   = 1
      capacity_type  = "SPOT"
      disk_size      = 30
      labels = {
        environment = "staging"
        nodegroup   = "spot"
      }
      taints = [{
        key    = "spot"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
  }

  # Feature Flags
  enable_load_balancer = true
  enable_monitoring    = true

  # Application Configuration
  app_replicas = 3

  # Tags
  tags = {
    Environment = "staging"
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

output "load_balancer_dns_name" {
  description = "Load balancer DNS name"
  value       = module.statista_infrastructure.load_balancer_dns_name
} 