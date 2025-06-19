#!/bin/bash
set -e

echo "⚡ Deploying to local Kubernetes cluster (FAST MODE)..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Kubernetes cluster is available
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Kubernetes cluster is not available."
    echo "Please ensure you have one of the following:"
    echo "  - Docker Desktop with Kubernetes enabled"
    echo "  - Minikube running"
    echo "  - Kind cluster running"
    exit 1
fi

# Build development Docker image (faster build, no model download)
echo "🔨 Building development Docker image..."
make build-dev

# Load image into cluster (for Kind and Minikube)
CLUSTER_TYPE=$(kubectl config current-context)
if [[ "$CLUSTER_TYPE" == "kind-"* ]]; then
    echo "📦 Loading image into Kind cluster..."
    kind load docker-image statista-api:dev
elif [[ "$CLUSTER_TYPE" == "minikube" ]]; then
    echo "📦 Loading image into Minikube..."
    minikube image load statista-api:dev
else
    echo "📦 Using local Docker image (Docker Desktop)..."
fi

# Deploy to Kubernetes in proper order
echo "🚀 Deploying to Kubernetes (FAST MODE)..."

# Create namespace and deploy resources
echo "📁 Creating namespace and deploying resources..."
kubectl apply -f kubernetes/local/namespace.yaml
kubectl apply -f kubernetes/local/configmap-fast.yaml
kubectl apply -f kubernetes/local/deployment-fast.yaml
kubectl apply -f kubernetes/local/service.yaml

# Wait for deployment to be ready (reduced timeout for fast mode)
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/statista-api -n statista --timeout=120s

# Set up HPA for auto-scaling
echo "📈 Setting up Horizontal Pod Autoscaler..."
kubectl apply -f kubernetes/hpa.yaml
echo "✅ HPA configured for auto-scaling"

# Get service information
echo "✅ Fast mode deployment completed successfully!"
echo ""
echo "📊 Service Information:"
kubectl get services -n statista

# Get pods
echo ""
echo "📱 Pods:"
kubectl get pods -n statista

# Provide access instructions
echo ""
echo "🌐 Access your application:"
SERVICE_TYPE=$(kubectl get service statista-api -n statista -o jsonpath='{.spec.type}')

if [[ "$SERVICE_TYPE" == "LoadBalancer" ]]; then
    echo "  Waiting for LoadBalancer IP..."
    kubectl get service statista-api -n statista -w &
    WATCH_PID=$!
    sleep 10
    kill $WATCH_PID 2>/dev/null || true
    
    EXTERNAL_IP=$(kubectl get service statista-api -n statista -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -z "$EXTERNAL_IP" ]; then
        EXTERNAL_IP=$(kubectl get service statista-api -n statista -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "localhost")
    fi
    
    if [ "$EXTERNAL_IP" != "localhost" ]; then
        echo "  Application URL: http://$EXTERNAL_IP:8000"
    else
        echo "  Application URL: http://localhost:8000"
    fi
else
    echo "  Use port-forward: kubectl port-forward service/statista-api 8000:8000 -n statista"
fi

echo ""
echo "⚡ FAST MODE ACTIVE:"
echo "  - Model loading: DISABLED"
echo "  - Search functionality: DISABLED"
echo "  - Startup time: OPTIMIZED"
echo ""
echo "💡 Useful commands:"
echo "  - View logs: kubectl logs -f deployment/statista-api -n statista"
echo "  - Scale app: kubectl scale deployment statista-api --replicas=2 -n statista"
echo "  - Port forward: kubectl port-forward service/statista-api 8000:8000 -n statista"
echo "  - Switch to normal mode: make deploy-local"
echo "  - Delete app: kubectl delete -f kubernetes/local/" 