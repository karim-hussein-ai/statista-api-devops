#!/bin/bash

echo "🧹 Comprehensive Cleanup Script"
echo "==============================="
echo ""

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl is not installed. Skipping Kubernetes cleanup."
        return 1
    fi
    return 0
}

# Function to check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed. Skipping Docker cleanup."
        return 1
    fi
    return 0
}

echo "🔍 Checking prerequisites..."

# Check kubectl
if check_kubectl; then
    echo "✅ kubectl found"
else
    echo "⚠️  kubectl not found - skipping Kubernetes cleanup"
fi

# Check Docker
if check_docker; then
    echo "✅ Docker found"
else
    echo "⚠️  Docker not found - skipping Docker cleanup"
fi

echo ""
echo "🚀 Starting cleanup process..."
echo ""

# 1. Clean up Kubernetes deployments
if check_kubectl; then
    echo "🗑️  Cleaning up Kubernetes deployments..."
    
    # Delete namespace if it exists
    if kubectl get namespace statista &> /dev/null; then
        echo "  - Deleting statista namespace..."
        kubectl delete namespace statista --force --grace-period=0 2>/dev/null || true
        echo "  ✅ Namespace deleted"
    else
        echo "  - No statista namespace found"
    fi
    
    # Delete any other statista-related resources
    echo "  - Cleaning up any remaining statista resources..."
    kubectl delete deployment statista-api --all-namespaces --force --grace-period=0 2>/dev/null || true
    kubectl delete service statista-api --all-namespaces --force --grace-period=0 2>/dev/null || true
    kubectl delete hpa statista-api-hpa --all-namespaces --force --grace-period=0 2>/dev/null || true
    kubectl delete configmap statista-api-config --all-namespaces --force --grace-period=0 2>/dev/null || true
    
    echo "  ✅ Kubernetes cleanup completed"
else
    echo "⏭️  Skipping Kubernetes cleanup (kubectl not available)"
fi

echo ""

# 2. Clean up Docker images
if check_docker; then
    echo "🐳 Cleaning up Docker images..."
    
    # Remove statista-api images
    echo "  - Removing statista-api Docker images..."
    docker rmi statista-api:latest 2>/dev/null || echo "    - statista-api:latest not found"
    docker rmi statista-api:dev 2>/dev/null || echo "    - statista-api:dev not found"
    docker rmi statista-api:optimized 2>/dev/null || echo "    - statista-api:optimized not found"
    
    # Remove dangling images
    echo "  - Removing dangling images..."
    docker image prune -f 2>/dev/null || true
    
    # Remove unused containers
    echo "  - Removing stopped containers..."
    docker container prune -f 2>/dev/null || true
    
    echo "  ✅ Docker cleanup completed"
else
    echo "⏭️  Skipping Docker cleanup (Docker not available)"
fi

echo ""

# 3. Clean up any port-forward processes
echo "🔌 Cleaning up port-forward processes..."
pkill -f "kubectl port-forward.*statista-api" 2>/dev/null || echo "  - No port-forward processes found"

echo ""

# 4. Clean up any local files
echo "📁 Cleaning up local files..."
if [ -f "statistics.db" ]; then
    rm -f statistics.db
    echo "  - Removed statistics.db"
fi

if [ -d ".cache" ]; then
    rm -rf .cache
    echo "  - Removed .cache directory"
fi

echo ""

# 5. Final verification
echo "🔍 Final verification..."

if check_kubectl; then
    echo "  - Checking for remaining statista resources..."
    kubectl get all --all-namespaces | grep statista 2>/dev/null || echo "    ✅ No statista resources found"
fi

if check_docker; then
    echo "  - Checking for remaining statista Docker images..."
    docker images | grep statista 2>/dev/null || echo "    ✅ No statista Docker images found"
fi

echo ""
echo "🎉 Cleanup completed successfully!"
echo ""
echo "💡 You can now start fresh with:"
echo "  make deploy-local-optimized  # Deploy optimized version"
echo "  make deploy-local            # Deploy normal version"
echo "  make deploy-local-fast       # Deploy fast version"
echo ""
echo "🧪 To test HPA scaling:"
echo "  make load-test-stress        # Run stress test"
echo "  make monitor-scaling         # Monitor scaling" 