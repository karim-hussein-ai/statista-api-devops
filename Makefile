.PHONY: build build-dev build-prod deploy deploy-local deploy-local-fast deploy-local-optimized deploy-aws health-check health-check-local clean clean-local load-test load-test-advanced load-test-stress monitor-scaling setup-hpa check-hpa install-metrics fix-hpa terraform-init terraform-plan terraform-apply terraform-destroy setup-aws setup-backend

# Build Docker image (production - includes model)
build: build-prod

# Build production Docker image (includes model download)
build-prod:
	docker build -t statista-api:latest -f docker/Dockerfile .

# Build optimized Docker image (pre-built FAISS index)
build-optimized:
	docker build -t statista-api:optimized -f docker/Dockerfile.optimized .

# Build development Docker image (skips model download for faster builds)
build-dev:
	docker build -t statista-api:dev -f docker/Dockerfile.dev .

# Setup AWS deployment prerequisites
setup-aws:
	@echo "🚀 Setting up AWS deployment prerequisites..."
	./scripts/setup-aws.sh

# Setup Terraform S3 backend infrastructure
setup-backend:
	@echo "🚀 Setting up Terraform S3 backend infrastructure..."
	./scripts/setup-backend.sh

# Deploy to AWS environment
deploy-aws:
	@if [ -z "$(ENV)" ]; then \
		echo "Usage: make deploy-aws ENV=dev|staging|prod"; \
		exit 1; \
	fi
	@echo "🚀 Deploying to AWS $(ENV) environment..."
	./scripts/deploy.sh $(ENV)

# Deploy to local Kubernetes (normal mode - full functionality with ML model)
deploy-local:
	@echo "🚀 Deploying to local Kubernetes (normal mode - full functionality)..."
	./scripts/deploy-local.sh

# Deploy to local Kubernetes (fast mode - no model loading)
deploy-local-fast:
	@echo "⚡ Deploying to local Kubernetes (fast mode)..."
	./scripts/deploy-local-fast.sh

# Deploy to local Kubernetes (optimized mode - pre-built FAISS index)
deploy-local-optimized:
	@echo "🚀 Deploying to local Kubernetes (optimized mode - pre-built index)..."
	./scripts/deploy-local-optimized.sh

# Check application health
health-check:
	@if [ -z "$(ENV)" ]; then \
		echo "Usage: make health-check ENV=dev|staging|prod"; \
		exit 1; \
	fi
	./scripts/health-check.sh $(ENV)

# Check local deployment health
health-check-local:
	@echo "🔍 Checking local deployment health..."
	@kubectl get pods -n statista
	@echo ""
	@echo "Testing API endpoint..."
	@curl -f http://localhost:8000 2>/dev/null && echo "✅ API is healthy" || echo "❌ API is not accessible (try: kubectl port-forward service/statista-api 8000:8000 -n statista)"

# Clean up Docker images
clean:
	docker image prune -f
	docker container prune -f

# Clean up local Kubernetes deployment
clean-local:
	kubectl delete -f kubernetes/local/ || true

# Clean up AWS environment
clean-aws:
	@if [ -z "$(ENV)" ]; then \
		echo "Usage: make clean-aws ENV=dev|staging|prod"; \
		exit 1; \
	fi
	@echo "🗑️ Destroying AWS $(ENV) environment..."
	cd terraform/environments/$(ENV) && terraform destroy -auto-approve

# Load testing commands
load-test-stress:
	@echo "🔥 Running stress test..."
	@./scripts/load-test-stress.sh

monitor-scaling:
	@echo "📊 Monitoring auto-scaling..."
	@./scripts/load-test-stress.sh http://localhost:8000 0 0 0 monitor

# Check HPA status
check-hpa:
	@echo "📊 Checking HPA status..."
	@./scripts/check-hpa.sh

# Install metrics server (required for HPA)
install-metrics:
	@echo "📊 Installing metrics server..."
	@./scripts/install-metrics-server.sh

# Fix HPA issues
fix-hpa:
	@echo "🔧 Fixing HPA configuration..."
	@kubectl delete hpa statista-api-hpa -n statista 2>/dev/null || true
	@kubectl apply -f kubernetes/hpa-simple.yaml
	@echo "✅ HPA reconfigured with simple settings"

# Terraform commands
terraform-init:
	@if [ -z "$(ENV)" ]; then \
		echo "Usage: make terraform-init ENV=dev|staging|prod"; \
		exit 1; \
	fi
	@echo "🔧 Initializing Terraform for $(ENV) environment..."
	cd terraform/environments/$(ENV) && terraform init -reconfigure

terraform-plan:
	@if [ -z "$(ENV)" ]; then \
		echo "Usage: make terraform-plan ENV=dev|staging|prod"; \
		exit 1; \
	fi
	@echo "📋 Planning Terraform changes for $(ENV) environment..."
	cd terraform/environments/$(ENV) && terraform plan

terraform-apply:
	@if [ -z "$(ENV)" ]; then \
		echo "Usage: make terraform-apply ENV=dev|staging|prod"; \
		exit 1; \
	fi
	@echo "🚀 Applying Terraform changes for $(ENV) environment..."
	cd terraform/environments/$(ENV) && terraform apply -auto-approve

terraform-destroy:
	@if [ -z "$(ENV)" ]; then \
		echo "Usage: make terraform-destroy ENV=dev|staging|prod"; \
		exit 1; \
	fi
	@echo "🗑️ Destroying $(ENV) environment..."
	cd terraform/environments/$(ENV) && terraform destroy -auto-approve

# Quick deployment aliases
deploy-dev:
	@$(MAKE) deploy-aws ENV=dev

deploy-staging:
	@$(MAKE) deploy-aws ENV=staging

deploy-prod:
	@$(MAKE) deploy-aws ENV=prod

# Quick health check aliases
health-dev: health-check ENV=dev
health-staging: health-check ENV=staging
health-prod: health-check ENV=prod

# Quick terraform aliases
init-dev:
	@$(MAKE) terraform-init ENV=dev

init-staging:
	@$(MAKE) terraform-init ENV=staging

init-prod:
	@$(MAKE) terraform-init ENV=prod

plan-dev:
	@$(MAKE) terraform-plan ENV=dev

plan-staging:
	@$(MAKE) terraform-plan ENV=staging

plan-prod:
	@$(MAKE) terraform-plan ENV=prod

apply-dev:
	@$(MAKE) terraform-apply ENV=dev

apply-staging:
	@$(MAKE) terraform-apply ENV=staging

apply-prod:
	@$(MAKE) terraform-apply ENV=prod

destroy-dev: terraform-destroy ENV=dev
destroy-staging: terraform-destroy ENV=staging
destroy-prod: terraform-destroy ENV=prod

# Help command
help:
	@echo "🚀 Statista API DevOps Commands"
	@echo "================================"
	@echo ""
	@echo "🏗️  Build Commands:"
	@echo "  make build              - Build production Docker image"
	@echo "  make build-optimized    - Build optimized Docker image (pre-built FAISS index)"
	@echo "  make build-dev          - Build development Docker image"
	@echo ""
	@echo "🚀 Deployment Commands:"
	@echo "  make deploy-local       - Deploy to local Kubernetes (normal mode)"
	@echo "  make deploy-local-fast  - Deploy to local Kubernetes (fast mode)"
	@echo "  make deploy-local-optimized - Deploy to local Kubernetes (optimized mode)"
	@echo "  make deploy-aws ENV=dev - Deploy to AWS environment"
	@echo "  make deploy-dev         - Deploy to AWS dev environment"
	@echo "  make deploy-staging     - Deploy to AWS staging environment"
	@echo "  make deploy-prod        - Deploy to AWS production environment"
	@echo ""
	@echo "🔧 Setup Commands:"
	@echo "  make setup-aws          - Setup AWS deployment prerequisites"
	@echo "  make setup-backend      - Setup Terraform S3 backend infrastructure"
	@echo ""
	@echo "🔍 Health Check Commands:"
	@echo "  make health-check-local - Check local deployment health"
	@echo "  make health-check ENV=dev - Check AWS environment health"
	@echo "  make health-dev         - Check AWS dev environment"
	@echo "  make health-staging     - Check AWS staging environment"
	@echo "  make health-prod        - Check AWS production environment"
	@echo ""
	@echo "🧪 Testing Commands:"
	@echo "  make load-test-stress   - Run stress test"
	@echo "  make monitor-scaling    - Monitor auto-scaling"
	@echo "  make check-hpa          - Check HPA status"
	@echo "  make install-metrics    - Install metrics server"
	@echo ""
	@echo "🏗️  Infrastructure Commands:"
	@echo "  make terraform-init ENV=dev   - Initialize Terraform"
	@echo "  make terraform-plan ENV=dev   - Plan Terraform changes"
	@echo "  make terraform-apply ENV=dev  - Apply Terraform changes"
	@echo "  make terraform-destroy ENV=dev - Destroy environment"
	@echo ""
	@echo "  make init-dev          - Initialize dev environment"
	@echo "  make plan-dev          - Plan dev changes"
	@echo "  make apply-dev         - Apply dev changes"
	@echo "  make destroy-dev       - Destroy dev environment"
	@echo ""
	@echo "🧹 Cleanup Commands:"
	@echo "  make clean             - Clean Docker images"
	@echo "  make clean-local       - Clean local deployment"
	@echo "  make cleanup-all       - Complete cleanup (start fresh)"
	@echo "  make clean-aws ENV=dev - Clean AWS environment"
	@echo ""
	@echo "📚 Examples:"
	@echo "  make deploy-local-fast && make load-test-stress"
	@echo "  make setup-backend && make init-dev && make apply-dev && make deploy-dev"
	@echo "  make deploy-prod && make health-prod"

# Clean up everything (complete reset)
cleanup-all:
	@echo "🧹 Running comprehensive cleanup..."
	./scripts/cleanup-all.sh 