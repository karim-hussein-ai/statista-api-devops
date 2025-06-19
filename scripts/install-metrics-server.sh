#!/bin/bash

echo "📊 Installing Kubernetes Metrics Server"
echo "======================================"
echo ""

# Check if metrics server is already installed
if kubectl get apiservice v1beta1.metrics.k8s.io >/dev/null 2>&1; then
    echo "✅ Metrics server is already installed"
    kubectl get apiservice v1beta1.metrics.k8s.io
    exit 0
fi

echo "🔍 Detecting Kubernetes cluster type..."
CLUSTER_TYPE=$(kubectl config current-context)

if [[ "$CLUSTER_TYPE" == "docker-desktop" ]]; then
    echo "🐳 Docker Desktop detected"
    echo "📦 Installing metrics server for Docker Desktop..."
    
    # Install metrics server for Docker Desktop
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Patch to work with Docker Desktop's self-signed certificates
    kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
    
elif [[ "$CLUSTER_TYPE" == "minikube" ]]; then
    echo "🖥️  Minikube detected"
    echo "📦 Installing metrics server for Minikube..."
    
    # Enable metrics server addon
    minikube addons enable metrics-server
    
elif [[ "$CLUSTER_TYPE" == "kind-"* ]]; then
    echo "🎯 Kind cluster detected"
    echo "📦 Installing metrics server for Kind..."
    
    # Install metrics server for Kind
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Patch to work with Kind's self-signed certificates
    kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
    
else
    echo "🌍 Generic Kubernetes cluster detected"
    echo "📦 Installing metrics server..."
    
    # Install metrics server
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
fi

echo ""
echo "⏳ Waiting for metrics server to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/metrics-server -n kube-system

echo ""
echo "✅ Metrics server installation completed!"
echo ""
echo "🔍 Verifying installation..."
kubectl get apiservice v1beta1.metrics.k8s.io

echo ""
echo "📊 Testing metrics collection..."
sleep 10  # Wait for metrics to start being collected
kubectl top nodes 2>/dev/null && echo "✅ Node metrics working" || echo "⏳ Node metrics not ready yet"
kubectl top pods -n statista 2>/dev/null && echo "✅ Pod metrics working" || echo "⏳ Pod metrics not ready yet"

echo ""
echo "💡 HPA should now work properly. Check with:"
echo "  make check-hpa"
echo "  kubectl get hpa -n statista" 