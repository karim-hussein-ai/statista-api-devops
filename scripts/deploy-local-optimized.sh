#!/bin/bash
set -e

echo "🚀 Deploying to local Kubernetes cluster (OPTIMIZED MODE - Pre-built FAISS index)..."

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

# Build optimized Docker image
echo "🔨 Building optimized Docker image (pre-built FAISS index)..."
make build-optimized

# Load image into cluster (for Kind and Minikube)
CLUSTER_TYPE=$(kubectl config current-context)
if [[ "$CLUSTER_TYPE" == "kind-"* ]]; then
    echo "📦 Loading image into Kind cluster..."
    kind load docker-image statista-api:optimized
elif [[ "$CLUSTER_TYPE" == "minikube" ]]; then
    echo "📦 Loading image into Minikube..."
    minikube image load statista-api:optimized
else
    echo "📦 Using local Docker image (Docker Desktop)..."
fi

# Deploy to Kubernetes in proper order
echo "🚀 Deploying to Kubernetes (OPTIMIZED MODE - Fast startup with pre-built index)..."

# Create namespace and deploy resources
echo "📁 Creating namespace and deploying resources..."
kubectl apply -f kubernetes/local/namespace.yaml
kubectl apply -f kubernetes/local/configmap.yaml

# Create optimized deployment that uses the optimized image
cat > /tmp/deployment-optimized.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: statista-api
  namespace: statista
  labels:
    app: statista-api
    environment: local
spec:
  replicas: 1
  selector:
    matchLabels:
      app: statista-api
  template:
    metadata:
      labels:
        app: statista-api
        environment: local
    spec:
      containers:
      - name: statista-api
        image: statista-api:optimized
        imagePullPolicy: Never
        ports:
        - containerPort: 8000
          name: http
        env:
        - name: PORT
          valueFrom:
            configMapKeyRef:
              name: statista-api-config
              key: PORT
        - name: ENVIRONMENT
          valueFrom:
            configMapKeyRef:
              name: statista-api-config
              key: ENVIRONMENT
        - name: FAST_MODE
          valueFrom:
            configMapKeyRef:
              name: statista-api-config
              key: FAST_MODE
        resources:
          requests:
            memory: "2Gi"
            cpu: "500m"
          limits:
            memory: "4Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 60
          periodSeconds: 15
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /
            port: 8000
          failureThreshold: 20
          periodSeconds: 10
EOF

kubectl apply -f /tmp/deployment-optimized.yaml
kubectl apply -f kubernetes/local/service.yaml

# Wait for deployment to be ready (much faster with pre-built index)
echo "⏳ Waiting for deployment to be ready (optimized startup)..."
kubectl rollout status deployment/statista-api -n statista --timeout=180s

# Set up HPA for auto-scaling
echo "📈 Setting up Horizontal Pod Autoscaler..."
kubectl apply -f kubernetes/hpa.yaml
echo "✅ HPA configured for auto-scaling"

# Get service information
echo "✅ Optimized mode deployment completed successfully!"
echo "⚡ Pre-built FAISS index enabled - much faster startup!"
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
echo "⚡ OPTIMIZED MODE ACTIVE:"
echo "  - Pre-built FAISS index: ✅"
echo "  - Pre-downloaded model: ✅"
echo "  - Fast startup: ~30-60 seconds"
echo "  - Full search functionality: ✅"
echo ""
echo "💡 Useful commands:"
echo "  - View logs: kubectl logs -f deployment/statista-api -n statista"
echo "  - Scale app: kubectl scale deployment statista-api --replicas=2 -n statista"
echo "  - Port forward: kubectl port-forward service/statista-api 8000:8000 -n statista"
echo "  - Test search: curl -X POST http://localhost:8000/find -H 'Content-Type: application/json' -d '{\"query\": \"statistics\", \"limit\": 5}'"
echo "  - Load test: make load-test-advanced"
echo "  - Delete app: kubectl delete -f kubernetes/local/"

# Clean up temp file
rm -f /tmp/deployment-optimized.yaml 