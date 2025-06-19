# Statista API DevOps

A complete DevOps setup for the Statista API with FastAPI, sentence transformers, and FAISS for semantic search. Supports both local development and multi-environment AWS deployments.

## 🚀 Features

- **FastAPI Application** with ML-powered semantic search
- **Multiple Deployment Modes**: Fast, Normal, and Optimized
- **Auto-scaling** with Horizontal Pod Autoscaler (HPA)
- **Multi-environment support**: Local, Dev, Staging, Production
- **Infrastructure as Code** with Terraform
- **Load testing** and monitoring tools
- **Docker** containerization with multi-stage builds
- **Kubernetes** orchestration

## 📋 Prerequisites

### For Local Development
- Docker Desktop or Minikube
- kubectl
- make

### For AWS Deployment
- AWS CLI configured
- Terraform
- kubectl
- Docker

## 🛠️ Quick Start

### **Option 1: Local Development (Recommended)**

```bash
# 🚀 Deploy optimized version (fastest startup)
make deploy-local-optimized

# 🔍 Check health
make health-check-local

# 🧪 Test HPA scaling
make load-test-stress
```

### **Option 2: Local Development (Fast Mode)**

```bash
# ⚡ Deploy fast mode (no ML model, search disabled)
make deploy-local-fast

# 🔍 Check health
make health-check-local
```

### **Option 3: Local Development (Full Mode)**

```bash
# 🐌 Deploy normal mode (full functionality, slower startup)
make deploy-local

# 🔍 Check health
make health-check-local

# 🧪 Test search functionality
curl -X POST http://localhost:8000/find \
  -H "Content-Type: application/json" \
  -d '{"query": "statistics data", "limit": 5}'
```

### **Option 4: AWS Deployment**

```bash
# ☁️ Setup AWS infrastructure
make setup-aws
make setup-backend

# 🚀 Deploy to environments
make deploy-dev      # Development
make deploy-staging  # Staging
make deploy-prod     # Production
```

## 🎯 Deployment Modes Comparison

| Mode | Startup Time | ML Model | Search | Use Case |
|------|-------------|----------|--------|----------|
| **Optimized** | ~30-60s | ✅ Pre-built | ✅ Full | **Production** |
| **Fast** | ~5s | ❌ None | ❌ Disabled | Development |
| **Normal** | ~5-10min | ✅ Runtime | ✅ Full | Testing |

## 🏗️ Architecture

### **Local Development**
- **Optimized Mode**: Pre-built FAISS index, fastest startup
- **Fast Mode**: No ML model, quick iteration
- **Normal Mode**: Full functionality, runtime model loading
- **Auto-scaling**: HPA configured for CPU/memory thresholds

### **AWS Environments**

#### Development (dev)
- **Region**: eu-central-1
- **Instance Types**: t3.medium
- **Nodes**: 1-3 nodes
- **Fast Mode**: Enabled for quick development

#### Staging (staging)
- **Region**: eu-central-1
- **Instance Types**: m5.large
- **Nodes**: 2-5 nodes
- **Fast Mode**: Disabled for full testing

#### Production (prod)
- **Region**: eu-central-1
- **Instance Types**: m5.large, r5.large (high memory)
- **Nodes**: 5-15 nodes (mixed on-demand and spot)
- **Fast Mode**: Disabled for full functionality
- **Monitoring**: Enabled
- **Backup**: Enabled

## 📊 Auto-Scaling (HPA)

### **Configuration**
- **CPU Threshold**: 50%
- **Memory Threshold**: 80%
- **Min Replicas**: 1
- **Max Replicas**: 10
- **Scale Up**: 100% increase or 2 pods every 15 seconds
- **Scale Down**: 10% decrease or 1 pod every 60 seconds

### **Testing Auto-Scaling**
```bash
# 🧪 Run stress test to trigger scaling
make load-test-stress

# 📊 Monitor scaling in real-time
make monitor-scaling

# 🔍 Check HPA status
make check-hpa

# 📊 Install metrics server (if needed)
make install-metrics
```

## 🧪 Testing & Monitoring

### **Load Testing**
```bash
# 🧪 Stress test (50 RPS, 20 users, 30 seconds)
make load-test-stress

# 📊 Monitor scaling
make monitor-scaling
```

### **Health Checks**
```bash
# 🔍 Local health check
make health-check-local

# ☁️ AWS environment health checks
make health-dev
make health-staging
make health-prod
```

## 🏗️ Infrastructure Management

### **Terraform Backend Setup**
```bash
# 🔧 Setup S3 backend infrastructure (one-time)
make setup-backend

# 🚀 Initialize environments
make init-dev
make init-staging
make init-prod
```

### **Terraform Commands**
```bash
# 📋 Plan changes
make plan-dev
make plan-staging
make plan-prod

# 🚀 Apply changes
make apply-dev
make apply-staging
make apply-prod

# 🗑️ Destroy environment
make destroy-dev
make destroy-staging
make destroy-prod
```

## 🔧 Configuration

### **Environment Variables**

#### Local Development
- `FAST_MODE=true` - Skip ML model loading
- `PORT=8000` - Application port
- `ENVIRONMENT=local` - Environment identifier

#### AWS Environments
Each environment has its own ConfigMap with environment-specific settings:
- **Dev**: Fast mode enabled, minimal resources
- **Staging**: Normal mode, moderate resources
- **Production**: Normal mode, high resources, monitoring enabled

### **Fast Mode vs Normal Mode**

| Feature | Fast Mode | Normal Mode |
|---------|-----------|-------------|
| Startup Time | ~5 seconds | ~30-60 seconds |
| ML Model | Not loaded | Loaded |
| Search Functionality | Disabled (503) | Enabled |
| Memory Usage | ~100MB | ~2GB |
| Use Case | Development | Production |

## 🧹 Cleanup

### **Local Cleanup**
```bash
# 🧹 Clean local deployment
make clean-local

# 🧹 Complete cleanup (start fresh)
make cleanup-all
```

### **AWS Cleanup**
```bash
# 🗑️ Destroy AWS environment
make destroy-dev
make destroy-staging
make destroy-prod
```

## 📁 Project Structure

```
statista-api-devops/
├── devops-demo-app/          # FastAPI application
├── docker/                   # Docker configurations
│   ├── Dockerfile           # Production build
│   ├── Dockerfile.optimized # Optimized build (pre-built index)
│   └── Dockerfile.dev       # Development build
├── kubernetes/               # K8s manifests
│   ├── environments/         # Environment-specific configs
│   └── local/               # Local development configs
├── scripts/                  # Deployment and utility scripts
├── terraform/                # Infrastructure as Code
│   ├── backend.tf           # Backend configuration
│   ├── environments/         # Environment configurations
│   └── modules/              # Reusable Terraform modules
├── docs/                     # Documentation
└── Makefile                  # Build and deployment commands
```

## 🚀 Deployment Workflows

### **Development Workflow**
```bash
# 1. Deploy optimized version
make deploy-local-optimized

# 2. Test functionality
curl http://localhost:8000/

# 3. Test search
curl -X POST http://localhost:8000/find \
  -H "Content-Type: application/json" \
  -d '{"query": "statistics", "limit": 5}'

# 4. Test HPA scaling
make load-test-stress
```

### **Production Workflow**
```bash
# 1. Setup infrastructure
make setup-backend
make init-prod
make apply-prod

# 2. Deploy application
make deploy-prod

# 3. Verify deployment
make health-prod
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally: `make deploy-local-optimized`
5. Test load: `make load-test-stress`
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License.