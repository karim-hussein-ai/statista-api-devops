# Terraform Backend Configuration

This document explains the Terraform backend configuration for remote state management using AWS S3 and DynamoDB.

## 🎯 Overview

The project uses AWS S3 for storing Terraform state files and DynamoDB for state locking to enable:
- **Remote State Storage**: State files stored securely in S3
- **State Locking**: Prevents concurrent modifications using DynamoDB
- **Team Collaboration**: Multiple team members can work safely
- **State History**: Versioning enabled for state file recovery
- **Security**: Encryption and access controls

## 🏗️ Backend Infrastructure

### S3 Bucket
- **Name**: `statista-terraform-state`
- **Region**: `eu-central-1`
- **Features**:
  - Server-side encryption (AES256)
  - Versioning enabled
  - Public access blocked
  - Bucket policy for encryption enforcement

### DynamoDB Table
- **Name**: `statista-terraform-locks`
- **Region**: `eu-central-1`
- **Features**:
  - Pay-per-request billing
  - LockID as primary key
  - Used for state locking

## 🚀 Setup Instructions

### 1. Setup Backend Infrastructure

```bash
# Setup AWS prerequisites first
make setup-aws

# Setup S3 backend infrastructure
make setup-backend
```

This will create:
- S3 bucket with encryption and versioning
- DynamoDB table for state locking
- Security policies and access controls

### 2. Initialize Environments

```bash
# Initialize dev environment
make init-dev

# Initialize staging environment
make init-staging

# Initialize prod environment
make init-prod
```

### 3. Deploy Infrastructure

```bash
# Deploy to dev
make apply-dev
make deploy-dev

# Deploy to staging
make apply-staging
make deploy-staging

# Deploy to production
make apply-prod
make deploy-prod
```

## 📁 Backend Configuration Files

### Root Backend Configuration
- **File**: `terraform/backend.tf`
- **Purpose**: Defines backend variables and outputs
- **Usage**: Referenced by environment configurations

### Environment-Specific Backends
- **Dev**: `terraform/environments/dev/main.tf`
  - State key: `dev/terraform.tfstate`
- **Staging**: `terraform/environments/staging/main.tf`
  - State key: `staging/terraform.tfstate`
- **Production**: `terraform/environments/prod/main.tf`
  - State key: `prod/terraform.tfstate`

## 🔧 Backend Configuration Details

### S3 Backend Settings
```hcl
backend "s3" {
  bucket         = "statista-terraform-state"
  key            = "dev/terraform.tfstate"  # Environment-specific
  region         = "eu-central-1"
  encrypt        = true
  dynamodb_table = "statista-terraform-locks"
}
```

### Security Features
- **Encryption**: All state files encrypted with AES256
- **Versioning**: State file history preserved
- **Access Control**: Public access blocked
- **State Locking**: Prevents concurrent modifications

## 🔍 State Management

### Viewing State
```bash
# View current state
terraform show

# List resources in state
terraform state list

# View specific resource
terraform state show aws_eks_cluster.main
```

### State Operations
```bash
# Import existing resources
terraform import aws_eks_cluster.main cluster-name

# Move resources
terraform state mv aws_eks_cluster.old aws_eks_cluster.new

# Remove resources from state
terraform state rm aws_eks_cluster.deleted
```

### State Backup and Recovery
```bash
# Backup current state
terraform state pull > backup.tfstate

# Restore state from backup
terraform state push backup.tfstate
```

## 🚨 Important Notes

### State File Security
- **Never commit state files** to version control
- **Use encryption** for all state files
- **Limit access** to S3 bucket and DynamoDB table
- **Enable versioning** for recovery

### Team Collaboration
- **Always run `terraform plan`** before applying
- **Use workspaces** for feature development
- **Coordinate deployments** to avoid conflicts
- **Review state changes** before applying

### Best Practices
- **Use consistent naming** for state keys
- **Separate state by environment** (dev/staging/prod)
- **Enable state locking** to prevent conflicts
- **Regular backups** of state files
- **Monitor state file size** and clean up old versions

## 🔧 Troubleshooting

### Common Issues

#### State Lock Error
```bash
# If state is locked, check DynamoDB table
aws dynamodb scan --table-name statista-terraform-locks --region eu-central-1

# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

#### S3 Access Denied
```bash
# Check bucket permissions
aws s3 ls s3://statista-terraform-state/

# Check IAM permissions
aws iam get-user
aws iam list-attached-user-policies --user-name <username>
```

#### DynamoDB Table Not Found
```bash
# Check if table exists
aws dynamodb describe-table --table-name statista-terraform-locks --region eu-central-1

# Recreate if needed
make setup-backend
```

### Recovery Procedures

#### State File Corruption
1. **Check S3 versioning** for previous versions
2. **Download backup** from S3
3. **Restore state** using `terraform state push`
4. **Verify resources** match state

#### Lost State File
1. **Check S3 bucket** for state files
2. **Import existing resources** manually
3. **Recreate state** from scratch
4. **Verify infrastructure** matches expectations

## 📚 Examples

### Complete Setup Workflow
```bash
# 1. Setup AWS and backend
make setup-aws
make setup-backend

# 2. Initialize environments
make init-dev
make init-staging
make init-prod

# 3. Deploy infrastructure
make apply-dev
make apply-staging
make apply-prod

# 4. Deploy applications
make deploy-dev
make deploy-staging
make deploy-prod
```

### State Management Examples
```bash
# View state for specific environment
cd terraform/environments/dev
terraform state list

# Import existing EKS cluster
terraform import module.statista_infrastructure.aws_eks_cluster.main existing-cluster-name

# Move resource to new module
terraform state mv aws_eks_cluster.main module.statista_infrastructure.aws_eks_cluster.main
```

## 🔐 Security Considerations

### IAM Permissions Required
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::statista-terraform-state",
        "arn:aws:s3:::statista-terraform-state/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:eu-central-1:*:table/statista-terraform-locks"
    }
  ]
}
```

### Network Security
- **VPC Endpoints**: Consider using VPC endpoints for S3 and DynamoDB
- **Private Subnets**: Deploy in private subnets when possible
- **Security Groups**: Restrict access to necessary ports only
- **Encryption**: Enable encryption in transit and at rest 