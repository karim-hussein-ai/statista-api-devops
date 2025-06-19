#!/bin/bash

echo "📊 HPA Status Check"
echo "=================="
echo ""

# Check if HPA exists
if kubectl get hpa statista-api-hpa -n statista >/dev/null 2>&1; then
    echo "✅ HPA is configured"
    echo ""
    echo "📈 HPA Details:"
    kubectl get hpa statista-api-hpa -n statista -o wide
    echo ""
    echo "🔧 HPA Configuration:"
    kubectl describe hpa statista-api-hpa -n statista
else
    echo "❌ HPA is not configured"
    echo ""
    echo "💡 To set up HPA:"
    echo "  kubectl apply -f kubernetes/hpa.yaml"
    echo ""
    echo "💡 Or deploy with auto-scaling:"
    echo "  make deploy-local"
    echo "  make deploy-local-fast"
fi

echo ""
echo "📱 Current Pod Status:"
kubectl get pods -n statista -l app=statista-api

echo ""
echo "💾 Resource Usage:"
kubectl top pods -n statista -l app=statista-api 2>/dev/null || echo "Metrics server not available" 