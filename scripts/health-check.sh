#!/bin/bash
set -e

ENV=${1:-dev}

# Validate environment
if [[ ! "$ENV" =~ ^(dev|staging|prod)$ ]]; then
  echo "Error: Environment must be 'dev', 'staging', or 'prod'"
  echo "Usage: ./health-check.sh [dev|staging|prod]"
  exit 1
fi

CLUSTER_NAME="statista-api-$ENV"
echo "Checking health for $ENV environment..."

# Update kubeconfig
aws eks update-kubeconfig --name $CLUSTER_NAME --region eu-central-1

# Check deployment status
echo "Checking deployment status..."
kubectl get deployment statista-api -n statista

# Check pods
echo "Checking pods..."
kubectl get pods -n statista -l app=statista-api

# Check service
echo "Checking service..."
kubectl get service statista-api -n statista

# Test health endpoint if available
echo "Testing health endpoint..."
ENDPOINT=$(kubectl get ingress statista-api -n statista -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -n "$ENDPOINT" ]; then
  curl -f "http://$ENDPOINT/health" || echo "Health endpoint not responding"
else
  echo "Ingress not ready yet"
fi

echo "✅ Health check completed" 