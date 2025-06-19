# Production Environment Configuration
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
    key            = "prod/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "statista-terraform-locks"
  }
}

# Call the root module
module "statista_infrastructure" {
  source = "../.."

  # Environment Configuration
  environment    = "prod"
  project_name   = "statista-api"
  aws_region     = "eu-central-1"

  # VPC Configuration
  vpc_cidr               = "10.2.0.0/16"
  public_subnet_cidrs    = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  private_subnet_cidrs   = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]

  # EKS Configuration
  cluster_version = "1.28"
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # Restrict in production
  
  node_groups = {
    general = {
      instance_types = ["m5.large"]
      min_size       = 3
      max_size       = 10
      desired_size   = 5
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      labels = {
        environment = "prod"
        nodegroup   = "general"
      }
      taints = []
    }
    spot = {
      instance_types = ["m5.large", "m5a.large", "m4.large"]
      min_size       = 1
      max_size       = 8
      desired_size   = 2
      capacity_type  = "SPOT"
      disk_size      = 50
      labels = {
        environment = "prod"
        nodegroup   = "spot"
      }
      taints = [{
        key    = "spot"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
    high_memory = {
      instance_types = ["r5.large"]
      min_size       = 0
      max_size       = 5
      desired_size   = 1
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      labels = {
        environment = "prod"
        nodegroup   = "high-memory"
        workload    = "memory-intensive"
      }
      taints = [{
        key    = "high-memory"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
  }

  # Feature Flags
  enable_load_balancer = true
  enable_monitoring    = true
  enable_backup        = true

  # Application Configuration
  app_replicas = 5

  # SSL Configuration (uncomment when certificate is available)
  # certificate_arn = "arn:aws:acm:eu-central-1:123456789012:certificate/abcd1234-5678-90ab-cdef-1234567890ab"
  # domain_name     = "api.statista.com"

  # Tags
  tags = {
    Environment = "prod"
    Project     = "statista-api"
    ManagedBy   = "terraform"
    Owner       = "devops-team"
    CostCenter  = "engineering"
    Compliance  = "required"
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

output "vpc_id" {
  description = "VPC ID"
  value       = module.statista_infrastructure.vpc_id
}

output "nat_gateway_ips" {
  description = "NAT Gateway IPs for whitelisting"
  value       = module.statista_infrastructure.nat_gateway_ips
} 