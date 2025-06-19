# Multi-Environment Deployment Guide

This guide covers how to deploy the Statista API to both local and AWS environments with full multi-environment support.

## 🎯 Overview

The project now supports:
- **Local Development**: Fast and normal modes
- **AWS Multi-Environment**: Dev, Staging, Production
- **Auto-scaling**: HPA with 50% CPU threshold
- **Load Testing**: Comprehensive testing tools
- **Infrastructure as Code**: Terraform for AWS

## 🚀 Quick Start Commands

### Local Development
```bash
# Fast mode (recommended for development)
make deploy-local-fast

# Normal mode (full functionality)
make deploy-local

# Health check
make health-check-local

# Load testing
make load-test-advanced
```

### AWS Deployment
```bash
# Setup AWS prerequisites
make setup-aws

# Deploy to environments
make deploy-dev
make deploy-staging
make deploy-prod

# Health checks
make health-dev
make health-staging
make health-prod
```

## 🏗️ Environment Configurations

### Local Environment
- **Fast Mode**: `FAST_MODE=true` (no ML model)
- **Resources**: Minimal (for development)
- **Auto-scaling**: Enabled
- **Access**: `kubectl port-forward`

### AWS Development (dev)
- **Region**: eu-central-1
- **Instance Types**: t3.medium
- **Nodes**: 1-3 nodes
- **Fast Mode**: Enabled
- **Features**: Basic ALB, auto-scaling

### AWS Staging (staging)
- **Region**: eu-central-1
- **Instance Types**: m5.large
- **Nodes**: 2-5 nodes
- **Fast Mode**: Disabled (full testing)
- **Features**: ALB, monitoring, auto-scaling

### AWS Production (prod)
- **Region**: eu-central-1
- **Instance Types**: m5.large, r5.large (high memory)
- **Nodes**: 5-15 nodes (mixed on-demand and spot)
- **Fast Mode**: Disabled (full functionality)
- **Features**: ALB, monitoring, backup, auto-scaling

## 📊 Auto-Scaling Configuration

### HPA Settings
- **CPU Threshold**: 50%
- **Memory Threshold**: 80%
- **Min Replicas**: 1
- **Max Replicas**: 10
- **Scale Up**: 100% increase or 2 pods every 15 seconds
- **Scale Down**: 10% decrease or 1 pod every 60 seconds

### Testing Auto-Scaling
```bash
# Monitor in real-time
make monitor-scaling

# Run stress test
make load-test-stress

# Check HPA status
make check-hpa
```

## 🧪 Load Testing

### Available Tests
```bash
# Basic load test
make load-test-advanced

# Stress test
make load-test-stress

# Custom load test
./scripts/load-test-advanced.sh http://localhost:8000 120 100 50 health
```

### Load Test Parameters
- **Duration**: Test duration in seconds
- **RPS**: Requests per second
- **Concurrent Users**: Number of simultaneous users
- **Endpoint**: Target endpoint (health, search, mixed)

## 🏗️ Infrastructure Management

### Terraform Commands
```bash
# Initialize
make init-dev
make init-staging
make init-prod

# Plan changes
make plan-dev
make plan-staging
make plan-prod

# Apply changes
make apply-dev
make apply-staging
make apply-prod

# Destroy environments
make destroy-dev
make destroy-staging
make destroy-prod
```

### Manual Deployment
```bash
# Deploy to specific environment
make deploy-aws ENV=dev
make deploy-aws ENV=staging
make deploy-aws ENV=prod
```

## 🔧 Configuration Files

### Environment ConfigMaps
- `kubernetes/environments/dev-configmap.yaml` - Development settings
- `kubernetes/environments/staging-configmap.yaml` - Staging settings
- `kubernetes/environments/prod-configmap.yaml` - Production settings
- `kubernetes/local/configmap.yaml` - Local development settings

### Terraform Configurations
- `terraform/environments/dev/main.tf` - Development infrastructure
- `terraform/environments/staging/main.tf` - Staging infrastructure
- `terraform/environments/prod/main.tf` - Production infrastructure

## 🚀 Deployment Workflows

### Development Workflow
1. **Local Testing**: `make deploy-local-fast`
2. **Load Testing**: `make load-test-advanced`
3. **Deploy to Dev**: `make deploy-dev`
4. **Test in Dev**: `make health-dev`

### Production Workflow
1. **Deploy to Staging**: `make deploy-staging`
2. **Test in Staging**: `make health-staging`
3. **Load Test Staging**: `make load-test-advanced`
4. **Deploy to Production**: `make deploy-prod`
5. **Monitor Production**: `make health-prod`

## 🔍 Monitoring and Troubleshooting

### Common Issues

#### HPA showing `<unknown>` targets
```bash
# Install metrics server
make install-metrics

# Check HPA status
make check-hpa
```

#### Port forwarding errors
```bash
# Kill existing port-forward processes
pkill -f "kubectl port-forward"

# Start fresh port-forward
kubectl port-forward service/statista-api 8000:8000 -n statista
```

#### Slow startup in normal mode
- This is expected when loading the ML model
- Use fast mode for development: `make deploy-local-fast`

### Useful Commands
```bash
# View all available commands
make help

# Check pod logs
kubectl logs -f deployment/statista-api -n statista

# Check HPA status
kubectl get hpa -n statista

# Scale manually
kubectl scale deployment statista-api --replicas=3 -n statista

# Check resource usage
kubectl top pods -n statista
```

## 📚 Examples

### Complete Local Development Session
```bash
# Deploy in fast mode
make deploy-local-fast

# Run load tests
make load-test-advanced

# Monitor scaling
make monitor-scaling

# Clean up
make clean-local
```

### Complete AWS Deployment Session
```bash
# Setup AWS
make setup-aws

# Deploy to dev
make deploy-dev

# Test and monitor
make health-dev
make load-test-advanced

# Deploy to staging
make deploy-staging

# Deploy to production
make deploy-prod
```

### Infrastructure Management
```bash
# Initialize and deploy dev environment
make init-dev
make apply-dev
make deploy-dev

# Update staging infrastructure
make plan-staging
make apply-staging

# Clean up dev environment
make destroy-dev
```

## 🎯 Best Practices

### Development
- Use fast mode for local development
- Test auto-scaling with load tests
- Monitor resource usage
- Use staging for integration testing

### Production
- Always test in staging first
- Monitor auto-scaling behavior
- Use appropriate instance types
- Enable monitoring and backup

### Security
- Use IAM roles and policies
- Restrict network access
- Enable encryption at rest
- Regular security updates

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review the logs: `kubectl logs -f deployment/statista-api -n statista`
3. Check HPA status: `make check-hpa`
4. Verify infrastructure: `make health-dev` 