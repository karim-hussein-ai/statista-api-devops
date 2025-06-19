# Setup Guide

This guide walks you through setting up the Statista API on AWS EKS.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Docker installed
- kubectl installed
- Terraform installed

## Quick Setup

### 1. Set up ECR Repository

```bash
./scripts/setup-ecr.sh eu-central-1
```

### 2. Build and Push Docker Image

```bash
make build
docker tag statista-api:latest <ECR_REGISTRY_URL>:latest
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin <ECR_REGISTRY_URL>
docker push <ECR_REGISTRY_URL>:latest
```

### 3. Deploy Infrastructure and Application

```bash
make deploy ENV=dev
```

### 4. Check Health

```bash
make health-check ENV=dev
```

## Architecture

- **EKS Cluster**: Managed Kubernetes cluster
- **VPC**: Isolated network with public/private subnets
- **Application Load Balancer**: Routes traffic to pods
- **ECR**: Container registry for application images

## Environments

- **dev**: Development environment with minimal resources
- **prod**: Production environment with higher availability

## Troubleshooting

### Check Cluster Status
```bash
kubectl get nodes
kubectl get pods -n statista
```

### View Logs
```bash
kubectl logs -f deployment/statista-api -n statista
```

### Scale Application
```bash
kubectl scale deployment statista-api --replicas=3 -n statista
``` 