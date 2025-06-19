#!/bin/bash
set -e

ENV=${1:-dev}

# Validate environment
if [[ ! "$ENV" =~ ^(dev|staging|prod)$ ]]; then
  echo "Error: Environment must be 'dev', 'staging', or 'prod'"
  echo "Usage: ./deploy.sh [dev|staging|prod]"
  exit 1
fi

echo "🚀 Deploying to $ENV environment..."

# Check if environment directory exists
if [ ! -d "terraform/environments/$ENV" ]; then
  echo "❌ Environment directory terraform/environments/$ENV not found"
  exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
  echo "❌ AWS CLI not configured. Please run 'aws configure' first."
  exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl > /dev/null 2>&1; then
  echo "❌ kubectl not found. Please install kubectl first."
  exit 1
fi

# Check if terraform is installed
if ! command -v terraform > /dev/null 2>&1; then
  echo "❌ terraform not found. Please install terraform first."
  exit 1
fi

# Apply Terraform for the specific environment
echo "📦 Setting up infrastructure..."
cd terraform/environments/$ENV

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
  echo "🔧 Initializing Terraform..."
  terraform init
fi

# Plan and apply Terraform
echo "📋 Planning Terraform changes..."
terraform plan -out=tfplan

echo "🚀 Applying Terraform changes..."
terraform apply tfplan

# Get outputs
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "")
REGION=$(terraform output -raw region 2>/dev/null || echo "eu-central-1")

if [ -z "$CLUSTER_NAME" ]; then
  echo "❌ Failed to get cluster name from Terraform outputs"
  exit 1
fi

echo "🔧 Configuring kubectl for cluster: $CLUSTER_NAME"
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION

# Deploy application
echo "🚢 Deploying application..."
cd ../../../kubernetes

# Apply Kubernetes manifests
echo "📦 Creating namespace..."
kubectl apply -f namespace.yaml

echo "⚙️ Applying environment configuration..."
kubectl apply -f environments/${ENV}-configmap.yaml

echo "🚀 Deploying application..."
kubectl apply -f deployment.yaml

echo "🔗 Creating service..."
kubectl apply -f service.yaml

echo "🌐 Setting up ingress..."
kubectl apply -f ingress.yaml

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/statista-api -n statista --timeout=600s

# Set up HPA for auto-scaling
echo "📈 Setting up Horizontal Pod Autoscaler..."
kubectl apply -f hpa.yaml

# Install metrics server if not present
echo "📊 Checking metrics server..."
if ! kubectl get deployment metrics-server -n kube-system > /dev/null 2>&1; then
  echo "📊 Installing metrics server..."
  ./scripts/install-metrics-server.sh
fi

echo "✅ Deployment completed successfully!"

# Get application URL
APP_URL=$(cd ../terraform/environments/$ENV && terraform output -raw application_url 2>/dev/null || echo "kubectl port-forward required")

# Show cluster info
echo ""
echo "📊 Cluster Information:"
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo "Environment: $ENV"
echo ""

echo "📱 Application Pods:"
kubectl get pods -n statista

echo ""
echo "🔗 Services:"
kubectl get services -n statista

echo ""
echo "📈 HPA Status:"
kubectl get hpa -n statista

echo ""
echo "🌐 Application URL: $APP_URL"

echo ""
echo "💡 Next steps:"
echo "  - Monitor application: kubectl logs -f deployment/statista-api -n statista"
echo "  - Check HPA: kubectl get hpa -n statista"
echo "  - Scale application: kubectl scale deployment statista-api --replicas=3 -n statista"
echo "  - Access application: $APP_URL"
echo "  - Load test: make load-test-advanced" 