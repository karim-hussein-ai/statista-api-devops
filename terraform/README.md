# Statista API Infrastructure

This Terraform project provides a modular and scalable infrastructure setup for the Statista API on AWS EKS.

## 🏗️ Architecture

```
terraform/
├── main.tf              # Root module orchestrating all components
├── variables.tf         # Global variable definitions
├── outputs.tf          # Global outputs
├── versions.tf         # Provider requirements
├── modules/            # Reusable infrastructure modules
│   ├── vpc/           # VPC networking module
│   ├── eks/           # EKS cluster module
│   ├── ecr/           # Container registry module
│   ├── alb/           # Application Load Balancer module
│   └── monitoring/    # Monitoring stack module
└── environments/       # Environment-specific configurations
    ├── dev/           # Development environment
    ├── staging/       # Staging environment
    └── prod/          # Production environment
```

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.5
- kubectl installed

### Deploy to Development

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### Deploy to Staging

```bash
cd terraform/environments/staging
terraform init
terraform plan
terraform apply
```

### Deploy to Production

```bash
cd terraform/environments/prod
terraform init
terraform plan
terraform apply
```

## 🔧 Environment Configurations

### Development (dev)
- **VPC CIDR**: 10.0.0.0/16
- **Node Groups**: 1 general group (t3.medium)
- **Replicas**: 2
- **Features**: Load balancer enabled, monitoring disabled
- **Cost**: Optimized for development

### Staging (staging)
- **VPC CIDR**: 10.1.0.0/16
- **Node Groups**: General + Spot instances
- **Replicas**: 3
- **Features**: Load balancer + monitoring enabled
- **Cost**: Balanced for testing

### Production (prod)
- **VPC CIDR**: 10.2.0.0/16
- **Node Groups**: General + Spot + High-memory instances
- **Replicas**: 5
- **Features**: All features enabled + backup
- **Cost**: Optimized for high availability

## 📦 Modules

### VPC Module (`modules/vpc/`)
Creates networking infrastructure:
- VPC with public/private subnets
- Internet Gateway and NAT Gateways
- Route tables and associations
- Kubernetes-ready subnet tagging

### EKS Module (`modules/eks/`)
Manages the Kubernetes cluster:
- EKS cluster with encryption
- Node groups with auto-scaling
- OIDC provider for IRSA
- Essential add-ons (CoreDNS, VPC-CNI, EBS CSI)
- CloudWatch logging

### ECR Module (`modules/ecr/`)
Container registry management:
- ECR repositories with scanning
- Lifecycle policies for image cleanup
- Cross-account access (optional)

### ALB Module (`modules/alb/`)
Load balancer configuration:
- Application Load Balancer
- Security groups
- HTTP/HTTPS listeners
- SSL termination support

### Monitoring Module (`modules/monitoring/`)
Observability stack (expandable):
- Monitoring namespace
- Ready for Prometheus/Grafana integration

## 🌍 Creating New Environments

To create a new environment (e.g., `testing`):

1. **Create environment directory**:
   ```bash
   mkdir terraform/environments/testing
   ```

2. **Create main.tf** based on existing environments:
   ```bash
   cp terraform/environments/dev/main.tf terraform/environments/testing/
   ```

3. **Customize configuration** in `terraform/environments/testing/main.tf`:
   ```hcl
   module "statista_infrastructure" {
     source = "../.."
     
     environment = "testing"
     vpc_cidr    = "10.3.0.0/16"
     # ... customize other variables
   }
   ```

4. **Deploy**:
   ```bash
   cd terraform/environments/testing
   terraform init
   terraform apply
   ```

## 🔒 Remote State Management

For production use, configure remote state:

1. **Create S3 bucket and DynamoDB table**:
   ```bash
   aws s3 mb s3://statista-terraform-state-$ENV
   aws dynamodb create-table \
     --table-name statista-terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
   ```

2. **Uncomment backend configuration** in environment's `main.tf`:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "statista-terraform-state-dev"
       key            = "dev/terraform.tfstate"
       region         = "eu-central-1"
       encrypt        = true
       dynamodb_table = "statista-terraform-locks"
     }
   }
   ```

3. **Initialize with remote state**:
   ```bash
   terraform init
   ```

## 📊 Outputs

Each environment provides useful outputs:

```bash
# Get cluster connection command
terraform output kubectl_config_command

# Get application URL
terraform output application_url

# Get ECR repository URLs
terraform output ecr_repository_urls

# Get VPC information
terraform output vpc_id
terraform output nat_gateway_ips
```

## 🔧 Customization

### Variables

Common variables you can customize:

- `cluster_version`: Kubernetes version
- `node_groups`: Node group configurations
- `enable_load_balancer`: Enable/disable ALB
- `enable_monitoring`: Enable/disable monitoring
- `certificate_arn`: SSL certificate for HTTPS
- `domain_name`: Custom domain name

### Node Groups

Customize node groups for different workloads:

```hcl
node_groups = {
  general = {
    instance_types = ["t3.medium"]
    min_size       = 1
    max_size       = 5
    desired_size   = 2
    capacity_type  = "ON_DEMAND"
    disk_size      = 20
    labels = { role = "general" }
    taints = []
  }
  spot = {
    instance_types = ["t3.medium", "t3a.medium"]
    capacity_type  = "SPOT"
    # ... other configuration
  }
}
```

## 🛠️ Maintenance

### Upgrading Kubernetes

1. Update `cluster_version` in environment configuration
2. Plan and apply changes:
   ```bash
   terraform plan
   terraform apply
   ```

### Scaling

Scale node groups by updating `desired_size` in the environment configuration.

### Monitoring

Enable monitoring by setting `enable_monitoring = true` in your environment.

## 🆘 Troubleshooting

### Common Issues

1. **Permission denied**: Ensure AWS credentials have sufficient permissions
2. **Resource limits**: Check AWS service quotas
3. **State conflicts**: Use remote state for team collaboration

### Useful Commands

```bash
# Debug Terraform
terraform plan -detailed-exitcode
terraform show

# Debug Kubernetes
kubectl cluster-info
kubectl get nodes
kubectl describe node <node-name>
```

## 🤝 Contributing

1. Create feature branch
2. Make changes to modules
3. Test in dev environment
4. Submit pull request

## 📚 Further Reading

- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/) 