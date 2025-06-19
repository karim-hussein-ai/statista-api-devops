# Terraform Backend Configuration
# This file defines the backend configuration for storing Terraform state

terraform {
  # S3 Backend Configuration
  backend "s3" {
    # These values will be provided via backend configuration
    # bucket         = "statista-terraform-state"
    # key            = "terraform.tfstate"
    # region         = "eu-central-1"
    # encrypt        = true
    # dynamodb_table = "statista-terraform-locks"
  }
}

# Backend configuration variables
variable "backend_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "statista-terraform-state-394256542096"
}

variable "backend_region" {
  description = "AWS region for S3 backend"
  type        = string
  default     = "eu-central-1"
}

variable "backend_dynamodb_table" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "statista-terraform-locks"
}

# Outputs for backend configuration
output "backend_config" {
  description = "Backend configuration for Terraform"
  value = {
    bucket         = var.backend_bucket
    region         = var.backend_region
    dynamodb_table = var.backend_dynamodb_table
    encrypt        = true
  }
}

output "backend_init_commands" {
  description = "Commands to initialize backend for each environment"
  value = {
    dev = "terraform init -backend-config='key=dev/terraform.tfstate' -backend-config='bucket=${var.backend_bucket}' -backend-config='region=${var.backend_region}' -backend-config='dynamodb_table=${var.backend_dynamodb_table}'"
    staging = "terraform init -backend-config='key=staging/terraform.tfstate' -backend-config='bucket=${var.backend_bucket}' -backend-config='region=${var.backend_region}' -backend-config='dynamodb_table=${var.backend_dynamodb_table}'"
    prod = "terraform init -backend-config='key=prod/terraform.tfstate' -backend-config='bucket=${var.backend_bucket}' -backend-config='region=${var.backend_region}' -backend-config='dynamodb_table=${var.backend_dynamodb_table}'"
  }
} 