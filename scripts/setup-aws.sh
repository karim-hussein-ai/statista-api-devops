#!/bin/bash
set -e

echo "🚀 Setting up AWS deployment prerequisites..."

# Check if AWS CLI is installed
if ! command -v aws > /dev/null 2>&1; then
  echo "❌ AWS CLI not found. Installing..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    brew install awscli
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
  else
    echo "❌ Please install AWS CLI manually: https://aws.amazon.com/cli/"
    exit 1
  fi
fi

# Check if kubectl is installed
if ! command -v kubectl > /dev/null 2>&1; then
  echo "❌ kubectl not found. Installing..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    brew install kubectl
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
  else
    echo "❌ Please install kubectl manually: https://kubernetes.io/docs/tasks/tools/"
    exit 1
  fi
fi

# Check if terraform is installed
if ! command -v terraform > /dev/null 2>&1; then
  echo "❌ terraform not found. Installing..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    brew install terraform
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt-get update && sudo apt-get install terraform
  else
    echo "❌ Please install terraform manually: https://www.terraform.io/downloads"
    exit 1
  fi
fi

# Check if Docker is installed
if ! command -v docker > /dev/null 2>&1; then
  echo "❌ Docker not found. Please install Docker first: https://docs.docker.com/get-docker/"
  exit 1
fi

# Check AWS configuration
echo "🔧 Checking AWS configuration..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
  echo "❌ AWS CLI not configured. Please run:"
  echo "   aws configure"
  echo ""
  echo "You'll need:"
  echo "  - AWS Access Key ID"
  echo "  - AWS Secret Access Key"
  echo "  - Default region (e.g., eu-central-1)"
  echo "  - Default output format (json)"
  exit 1
fi

# Get AWS account info
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)
AWS_USER=$(aws sts get-caller-identity --query Arn --output text)

echo "✅ AWS Configuration:"
echo "  Account: $AWS_ACCOUNT"
echo "  Region: $AWS_REGION"
echo "  User: $AWS_USER"

# Check required AWS services
echo ""
echo "🔍 Checking AWS service permissions..."

# Check EKS permissions
if ! aws eks list-clusters > /dev/null 2>&1; then
  echo "⚠️  Warning: EKS permissions not available"
fi

# Check ECR permissions
if ! aws ecr describe-repositories > /dev/null 2>&1; then
  echo "⚠️  Warning: ECR permissions not available"
fi

# Check VPC permissions
if ! aws ec2 describe-vpcs --max-items 1 > /dev/null 2>&1; then
  echo "⚠️  Warning: EC2/VPC permissions not available"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "🚀 Next steps:"
echo "  1. Deploy to dev: make deploy-dev"
echo "  2. Deploy to staging: make deploy-staging"
echo "  3. Deploy to prod: make deploy-prod"
echo ""
echo "📚 Examples:"
echo "  make init-dev && make apply-dev && make deploy-dev"
echo "  make deploy-local-fast  # For local testing" 