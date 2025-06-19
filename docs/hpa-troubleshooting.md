# HPA Troubleshooting Guide

This guide helps you fix common HPA (Horizontal Pod Autoscaler) issues, especially when the metrics server is not available.

## 🚨 Common Issues

### Issue 1: HPA Shows `<unknown>` Targets
```
NAME               REFERENCE                 TARGETS                                     MINPODS   MAXPODS   REPLICAS   AGE
statista-api-hpa   Deployment/statista-api   cpu: <unknown>/70%, memory: <unknown>/80%   1         10        1          6m15s
```

**Cause**: Metrics server is not installed or not working
**Solution**: Install metrics server

### Issue 2: "Metrics server not available"
```
💾 Resource Usage:
Metrics server not available
```

**Cause**: Kubernetes metrics server is missing
**Solution**: Install metrics server

### Issue 3: HPA Not Scaling
**Cause**: Various reasons including missing metrics, incorrect configuration, or insufficient load

## 🔧 Solutions

### Solution 1: Install Metrics Server (Recommended)

```bash
# Install metrics server
make install-metrics

# Or manually
./scripts/install-metrics-server.sh
```

**What this does**:
- Detects your Kubernetes cluster type (Docker Desktop, Minikube, Kind)
- Installs the appropriate metrics server
- Configures it for your cluster type
- Tests the installation

### Solution 2: Use Simple HPA Configuration

```bash
# Fix HPA with simple configuration
make fix-hpa

# Or manually
kubectl delete hpa statista-api-hpa -n statista
kubectl apply -f kubernetes/hpa-simple.yaml
```

**What this does**:
- Uses a simpler HPA configuration
- Works better with limited metrics
- Reduces complexity

### Solution 3: Manual Scaling (Fallback)

If HPA still doesn't work, you can manually scale:

```bash
# Scale up to 3 pods
kubectl scale deployment statista-api --replicas=3 -n statista

# Scale down to 1 pod
kubectl scale deployment statista-api --replicas=1 -n statista

# Check current replicas
kubectl get deployment statista-api -n statista
```

## 📊 Verification Steps

### Step 1: Check Metrics Server
```bash
# Check if metrics server is installed
kubectl get apiservice v1beta1.metrics.k8s.io

# Check metrics server pods
kubectl get pods -n kube-system | grep metrics-server

# Test metrics collection
kubectl top nodes
kubectl top pods -n statista
```

### Step 2: Check HPA Status
```bash
# Check HPA
make check-hpa

# Or manually
kubectl get hpa -n statista
kubectl describe hpa statista-api-hpa -n statista
```

### Step 3: Test Scaling
```bash
# Run load test
make load-test-stress

# Monitor scaling
make monitor-scaling
```

## 🎯 Quick Fix Commands

### For Docker Desktop
```bash
# Install metrics server for Docker Desktop
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```

### For Minikube
```bash
# Enable metrics server addon
minikube addons enable metrics-server
```

### For Kind
```bash
# Install metrics server for Kind
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```

## 🔍 Diagnostic Commands

### Check Cluster Type
```bash
kubectl config current-context
```

### Check Available APIs
```bash
kubectl api-resources | grep metrics
```

### Check Metrics Server Logs
```bash
kubectl logs -n kube-system deployment/metrics-server
```

### Check HPA Events
```bash
kubectl get events -n statista --sort-by='.lastTimestamp' | grep -E "(HPA|Scaled|metrics)"
```

## 📈 Expected Behavior After Fix

### With Metrics Server Working
```
NAME               REFERENCE                 TARGETS           MINPODS   MAXPODS   REPLICAS   AGE
statista-api-hpa   Deployment/statista-api   cpu: 45%/70%      1         10        2          10m
```

### Resource Usage Should Show
```
💾 Resource Usage:
NAME                            CPU(cores)   MEMORY(bytes)
statista-api-6cd8b9fcc8-wgwvc   45m          512Mi
statista-api-6cd8b9fcc8-xyz12   38m          498Mi
```

## 🚀 Complete Fix Workflow

```bash
# 1. Install metrics server
make install-metrics

# 2. Wait for metrics to be available
sleep 30

# 3. Check HPA status
make check-hpa

# 4. Test with load
make load-test-stress

# 5. Monitor scaling
make monitor-scaling
```

## 💡 Alternative Approaches

### If Metrics Server Still Doesn't Work

1. **Use Manual Scaling**: Scale pods manually based on load
2. **Use External Metrics**: Configure HPA with external metrics (requires Prometheus)
3. **Use Custom Metrics**: Set up custom metrics with Prometheus adapter
4. **Use Cron-based Scaling**: Scale based on time schedules

### Manual Scaling Script
```bash
#!/bin/bash
# Simple auto-scaling script
while true; do
    # Check CPU usage
    CPU_USAGE=$(kubectl top pods -n statista --no-headers | awk '{sum+=$2} END {print sum/NR}')
    
    if (( $(echo "$CPU_USAGE > 70" | bc -l) )); then
        echo "High CPU usage ($CPU_USAGE%), scaling up..."
        kubectl scale deployment statista-api --replicas=3 -n statista
    elif (( $(echo "$CPU_USAGE < 30" | bc -l) )); then
        echo "Low CPU usage ($CPU_USAGE%), scaling down..."
        kubectl scale deployment statista-api --replicas=1 -n statista
    fi
    
    sleep 30
done
```

## 🎯 Success Criteria

After fixing, you should see:

- ✅ `kubectl get hpa` shows actual CPU/memory percentages
- ✅ `kubectl top pods` works and shows resource usage
- ✅ HPA scales pods up/down based on load
- ✅ No `<unknown>` targets in HPA status
- ✅ Metrics server pods are running in `kube-system` namespace 