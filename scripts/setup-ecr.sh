#!/bin/bash
# scripts/setup-ecr.sh

set -e

REGION=${1:-eu-central-1}
REPO_NAME="statista-api"

echo "Setting up ECR repository: $REPO_NAME in region: $REGION"

# Create ECR repository if it doesn't exist
if ! aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION >/dev/null 2>&1; then
    echo "Creating ECR repository..."
    aws ecr create-repository \
        --repository-name $REPO_NAME \
        --region $REGION
    echo "✅ ECR repository created"
else
    echo "ECR repository already exists"
fi

# Get registry URL
REGISTRY_URL=$(aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION --query 'repositories[0].repositoryUri' --output text)

echo "✅ ECR setup complete"
echo "Registry URL: $REGISTRY_URL"
echo ""
echo "To push images:"
echo "1. docker build -t $REPO_NAME ."
echo "2. docker tag $REPO_NAME:latest $REGISTRY_URL:latest"
echo "3. aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REGISTRY_URL"
echo "4. docker push $REGISTRY_URL:latest" 