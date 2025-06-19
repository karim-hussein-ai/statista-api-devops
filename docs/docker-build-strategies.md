# Docker Build Strategies

This document explains the different Docker build strategies available for the Statista API, optimized for different use cases.

## Build Strategies

### 1. Production Build (`docker/Dockerfile`)
**Command**: `make build` or `make build-prod`
**Image Tag**: `statista-api:latest`
**Model Download**: ✅ During build time
**Use Case**: Production deployments, staging, full functionality testing

**Pros**:
- Model is immediately available when container starts
- No runtime model download delays
- Consistent behavior across all environments
- Better for production reliability

**Cons**:
- Larger image size (~500MB+ larger)
- Longer build times
- More storage requirements

### 2. Development Build (`docker/Dockerfile.dev`)
**Command**: `make build-dev`
**Image Tag**: `statista-api:dev`
**Model Download**: ❌ Skipped during build
**Use Case**: Local development, fast iteration, testing

**Pros**:
- Much faster build times
- Smaller image size
- Perfect for development iteration
- Works well with `FAST_MODE=true`

**Cons**:
- Model must be downloaded at runtime if `FAST_MODE=false`
- Initial startup delay when model is needed
- Not suitable for production

## Environment-Specific Usage

### Local Development
```bash
# Fast builds for local development
make build-dev
make deploy-local
```
- Uses `statista-api:dev` image
- `FAST_MODE=true` by default
- No model download needed

### AWS Development Environment
```bash
# Production build for AWS dev environment
make build
make deploy ENV=dev
```
- Uses `statista-api:latest` image
- `FAST_MODE=true` (configured via ConfigMap)
- Model available but not used

### AWS Staging/Production
```bash
# Production build for staging/production
make build
make deploy ENV=staging
make deploy ENV=prod
```
- Uses `statista-api:latest` image
- `FAST_MODE=false` (configured via ConfigMap)
- Full functionality with model

## Build Time Comparison

| Build Type | Model Download | Build Time | Image Size | Use Case |
|------------|----------------|------------|------------|----------|
| **Development** | ❌ Skipped | ~2-3 minutes | ~800MB | Local dev, fast iteration |
| **Production** | ✅ Included | ~5-8 minutes | ~1.3GB | Production, staging |

## Recommendations

### For Development Teams
- Use `make build-dev` for local development
- Use `make build` for AWS deployments
- Set `FAST_MODE=true` in development environments

### For Production
- Always use `make build` (production Dockerfile)
- Set `FAST_MODE=false` in production
- Consider using multi-stage builds for optimization

### For CI/CD Pipelines
- Use production builds for all AWS environments
- Use development builds only for local testing
- Cache Docker layers for faster builds

## Advanced: Multi-Stage Build (Future Enhancement)

For even more optimization, consider implementing a multi-stage build:

```dockerfile
# Stage 1: Build with model
FROM python:3.11-slim as model-builder
# ... install dependencies and download model

# Stage 2: Runtime with optional model
FROM python:3.11-slim
# ... copy from model-builder conditionally
```

This would allow:
- Conditional model inclusion based on build arguments
- Smaller runtime images when model isn't needed
- Single Dockerfile for all use cases 