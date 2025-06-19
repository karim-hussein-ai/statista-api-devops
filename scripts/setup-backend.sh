#!/bin/bash
set -e

echo "🚀 Setting up Terraform S3 Backend Infrastructure..."

# Configuration
BUCKET_NAME="statista-terraform-state-394256542096"
DYNAMODB_TABLE="statista-terraform-locks"
REGION="eu-central-1"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
  echo "❌ AWS CLI not configured. Please run 'aws configure' first."
  exit 1
fi

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✅ Using AWS Account: $AWS_ACCOUNT_ID"

# Create S3 bucket for Terraform state
echo "📦 Creating S3 bucket for Terraform state..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "✅ S3 bucket '$BUCKET_NAME' already exists"
else
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION"
  echo "✅ S3 bucket '$BUCKET_NAME' created successfully"
fi

# Enable versioning on the bucket
echo "🔄 Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

# Enable server-side encryption
echo "🔐 Enabling server-side encryption..."
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'

# Block public access
echo "🚫 Blocking public access..."
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create DynamoDB table for state locking
echo "🔒 Creating DynamoDB table for state locking..."
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" >/dev/null 2>&1; then
  echo "✅ DynamoDB table '$DYNAMODB_TABLE' already exists"
else
  aws dynamodb create-table \
    --table-name "$DYNAMODB_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"
  echo "✅ DynamoDB table '$DYNAMODB_TABLE' created successfully"
fi

# Wait for DynamoDB table to be active
echo "⏳ Waiting for DynamoDB table to be active..."
aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$REGION"

# Create bucket policy for additional security
echo "📋 Creating bucket policy..."
cat > /tmp/bucket-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUnencryptedObjectUploads",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::$BUCKET_NAME/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      }
    },
    {
      "Sid": "DenyIncorrectEncryptionHeader",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::$BUCKET_NAME/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      }
    },
    {
      "Sid": "DenyUnencryptedObjectUploads",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::$BUCKET_NAME/*",
      "Condition": {
        "Null": {
          "s3:x-amz-server-side-encryption": "true"
        }
      }
    }
  ]
}
EOF

aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy file:///tmp/bucket-policy.json
rm /tmp/bucket-policy.json

echo ""
echo "✅ Terraform Backend Infrastructure Setup Complete!"
echo ""
echo "📊 Backend Configuration:"
echo "  S3 Bucket: $BUCKET_NAME"
echo "  DynamoDB Table: $DYNAMODB_TABLE"
echo "  Region: $REGION"
echo "  Encryption: Enabled"
echo "  Versioning: Enabled"
echo "  Public Access: Blocked"
echo ""
echo "🚀 Next Steps:"
echo "  1. Initialize dev environment: make init-dev"
echo "  2. Initialize staging environment: make init-staging"
echo "  3. Initialize prod environment: make init-prod"
echo ""
echo "📚 Example:"
echo "  make init-dev && make apply-dev && make deploy-dev" 