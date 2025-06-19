# Auto-Scaling Testing Guide

This guide explains how to test auto-scaling functionality with load testing for the Statista API.

## 🎯 Overview

Auto-scaling allows your application to automatically scale up or down based on demand. This guide shows you how to:

1. Set up Horizontal Pod Autoscaler (HPA)
2. Generate load to trigger scaling
3. Monitor scaling behavior
4. Analyze results

## 🚀 Quick Start

### 1. Deploy with Auto-Scaling (Automatic)

```bash
# Deploy the application with auto-scaling (HPA included)
make deploy-local

# Or for fast mode with auto-scaling
make deploy-local-fast

# Port forward to access the API
kubectl port-forward service/statista-api 8000:8000 -n statista
```

**Note**: HPA is now automatically set up with every deployment - no separate setup required!

### 2. Run Load Tests

```bash
# Basic load test (10 RPS for 60 seconds)
make load-test

# Advanced load test with detailed metrics
make load-test-advanced

# Stress test (50 RPS for 30 seconds)
make load-test-stress

# Monitor scaling in real-time
make monitor-scaling
```

## 📊 HPA Configuration

The HPA is configured with the following settings:

```yaml
minReplicas: 1
maxReplicas: 10
cpuTarget: 70%
memoryTarget: 80%
```

### Scaling Behavior:
- **Scale Up**: When CPU > 70% OR Memory > 80%
- **Scale Down**: When CPU < 70% AND Memory < 80%
- **Stabilization**: 60s for scale up, 300s for scale down

## 🔧 Load Testing Options

### Basic Load Test
```bash
./scripts/load-test.sh [URL] [DURATION] [RPS] [USERS] [ENDPOINT]
```

**Examples:**
```bash
# Default test (10 RPS, 60s, 5 users)
./scripts/load-test.sh

# High load test (20 RPS, 120s, 10 users)
./scripts/load-test.sh http://localhost:8000 120 20 10

# Light load test (5 RPS, 30s, 3 users)
./scripts/load-test.sh http://localhost:8000 30 5 3
```

### Advanced Load Test (Recommended)
```bash
./scripts/load-test-advanced.sh [URL] [DURATION] [RPS] [USERS] [TEST_TYPE]
```

**Test Types:**
- `search` - Test search endpoint
- `health` - Test health endpoint
- `mixed` - Test both endpoints
- `stress` - High-intensity stress test
- `monitor` - Real-time monitoring only

**Examples:**
```bash
# Search endpoint test
./scripts/load-test-advanced.sh http://localhost:8000 60 15 8 search

# Mixed endpoints test
./scripts/load-test-advanced.sh http://localhost:8000 90 12 6 mixed

# Stress test
./scripts/load-test-advanced.sh http://localhost:8000 30 50 20 stress

# Monitor only
./scripts/load-test-advanced.sh http://localhost:8000 0 0 0 monitor
```

## 📈 Monitoring Auto-Scaling

### Real-Time Monitoring
```bash
# Start monitoring
make monitor-scaling

# Or directly
./scripts/load-test-advanced.sh http://localhost:8000 0 0 0 monitor
```

### Manual Monitoring Commands
```bash
# Check HPA status
kubectl get hpa -n statista

# Check pod count
kubectl get pods -n statista -l app=statista-api

# Check resource usage
kubectl top pods -n statista -l app=statista-api

# Check scaling events
kubectl get events -n statista --sort-by='.lastTimestamp' | grep -E "(HPA|Scaled)"
```

## 🎯 Load Testing Scenarios

### Scenario 1: Light Load (Development)
```bash
# 5 RPS for 30 seconds
make load-test-advanced
./scripts/load-test-advanced.sh http://localhost:8000 30 5 3 search
```
**Expected Result**: No scaling (CPU/Memory < 70%)

### Scenario 2: Moderate Load (Testing)
```bash
# 15 RPS for 60 seconds
./scripts/load-test-advanced.sh http://localhost:8000 60 15 8 search
```
**Expected Result**: Possible scale up to 2-3 pods

### Scenario 3: High Load (Stress Testing)
```bash
# 50 RPS for 30 seconds
make load-test-stress
```
**Expected Result**: Scale up to 5-8 pods

### Scenario 4: Burst Load (Spike Testing)
```bash
# 100 RPS for 10 seconds
./scripts/load-test-advanced.sh http://localhost:8000 10 100 25 stress
```
**Expected Result**: Rapid scale up to max pods

## 📊 Analyzing Results

### Key Metrics to Monitor

1. **Pod Count**: Should increase/decrease based on load
2. **CPU Usage**: Should trigger scaling at 70%
3. **Memory Usage**: Should trigger scaling at 80%
4. **Response Time**: Should remain stable during scaling
5. **Error Rate**: Should remain low

### Expected Scaling Behavior

| Load Level | CPU Usage | Memory Usage | Expected Pods | Scale Time |
|------------|-----------|--------------|---------------|------------|
| Light | < 50% | < 60% | 1 | N/A |
| Moderate | 50-70% | 60-80% | 1-2 | 60s |
| High | 70-90% | 80-95% | 2-5 | 60s |
| Very High | > 90% | > 95% | 5-10 | 60s |

### Troubleshooting

#### No Scaling Occurs
```bash
# Check HPA status
kubectl describe hpa statista-api-hpa -n statista

# Check metrics server
kubectl get apiservice v1beta1.metrics.k8s.io

# Check resource requests/limits
kubectl describe deployment statista-api -n statista
```

#### Scaling Too Aggressively
```bash
# Adjust HPA settings
kubectl patch hpa statista-api-hpa -n statista -p '{"spec":{"metrics":[{"type":"Resource","resource":{"name":"cpu","target":{"type":"Utilization","averageUtilization":80}}}]}}'
```

#### Scaling Too Slowly
```bash
# Reduce stabilization window
kubectl patch hpa statista-api-hpa -n statista -p '{"spec":{"behavior":{"scaleUp":{"stabilizationWindowSeconds":30}}}}'
```

## 🔄 Cleanup

```bash
# Remove HPA
kubectl delete hpa statista-api-hpa -n statista

# Scale down manually
kubectl scale deployment statista-api --replicas=1 -n statista

# Clean up deployment
make clean-local
```

## 💡 Best Practices

1. **Start Small**: Begin with light load tests
2. **Monitor Resources**: Watch CPU and memory usage
3. **Test Gradually**: Increase load incrementally
4. **Check Metrics**: Ensure metrics server is working
5. **Validate Scaling**: Verify pods are actually scaling
6. **Clean Up**: Scale down after testing

## 🎯 Success Criteria

A successful auto-scaling test should show:

- ✅ Pods scale up when load increases
- ✅ Pods scale down when load decreases
- ✅ Response times remain stable
- ✅ No errors during scaling
- ✅ Resource usage stays within limits
- ✅ Scaling happens within expected timeframes 