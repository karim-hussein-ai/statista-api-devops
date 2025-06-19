# General Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "statista-api"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# EKS Configuration
variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to cluster endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to cluster endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks that can access the public cluster endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Node Group Configuration
variable "node_groups" {
  description = "EKS node group configurations"
  type = map(object({
    instance_types   = list(string)
    min_size        = number
    max_size        = number
    desired_size    = number
    capacity_type   = string
    disk_size       = number
    labels          = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
  default = {
    general = {
      instance_types = ["t3.medium"]
      min_size      = 1
      max_size      = 10
      desired_size  = 2
      capacity_type = "ON_DEMAND"
      disk_size     = 20
      ami_type      = "AL2023_x86_64"
      labels = {
        role = "general"
      }
      taints = []
    }
  }
}

# Application Configuration
variable "app_name" {
  description = "Application name"
  type        = string
  default     = "statista-api"
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8000
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2
}

variable "app_image" {
  description = "Application Docker image"
  type        = string
  default     = "statista-api:latest"
}

# ECR Configuration
variable "ecr_repositories" {
  description = "List of ECR repositories to create"
  type        = list(string)
  default     = ["statista-api"]
}

variable "ecr_lifecycle_policy" {
  description = "ECR lifecycle policy"
  type        = string
  default     = ""
}

# Load Balancer Configuration
variable "enable_load_balancer" {
  description = "Enable Application Load Balancer"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = ""
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus, Grafana)"
  type        = bool
  default     = false
}

variable "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring"
  type        = string
  default     = "monitoring"
}

# Backup Configuration
variable "enable_backup" {
  description = "Enable backup for EKS cluster"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 30
} 