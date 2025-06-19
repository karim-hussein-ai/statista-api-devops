#!/bin/bash

# Stress Testing Script for Statista API
# Uses 'hey' for high-load stress testing

set -e

# Configuration
BASE_URL=${1:-"http://localhost:8000"}
DURATION=${2:-60}
RPS=${3:-50}
CONCURRENT_USERS=${4:-20}

echo "🔥 Stress Testing Statista API"
echo "=============================="
echo "Base URL: $BASE_URL"
echo "Duration: ${DURATION}s"
echo "Requests per second: $RPS"
echo "Concurrent users: $CONCURRENT_USERS"
echo ""

# Check if hey is installed
if ! command -v hey &> /dev/null; then
    echo "❌ 'hey' is not installed. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install hey
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        wget -O hey https://github.com/rakyll/hey/releases/download/v0.1.4/hey_linux_amd64
        chmod +x hey
        sudo mv hey /usr/local/bin/
    else
        echo "❌ Please install 'hey' manually: https://github.com/rakyll/hey"
        exit 1
    fi
fi

# Check if the API is accessible
echo "🔍 Checking API availability..."
if ! curl -f "$BASE_URL/" > /dev/null 2>&1; then
    echo "❌ API is not accessible at $BASE_URL"
    echo "💡 Make sure to run: kubectl port-forward service/statista-api 8000:8000 -n statista"
    exit 1
fi
echo "✅ API is accessible"

# Check current pod count
echo ""
echo "📊 Current deployment status:"
kubectl get pods -n statista -l app=statista-api

echo ""
echo "🔍 Current HPA status:"
kubectl get hpa -n statista 2>/dev/null || echo "No HPA configured"

echo ""
echo "🔥 Starting stress test..."

# Function to monitor scaling in real-time
monitor_scaling() {
    echo ""
    echo "📊 Monitoring auto-scaling in real-time..."
    echo "Press Ctrl+C to stop monitoring"
    echo ""
    
    while true; do
        clear
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Auto-scaling Monitor"
        echo "================================================"
        echo ""
        
        # Pod status
        echo "📱 Pod Status:"
        kubectl get pods -n statista -l app=statista-api -o wide
        
        echo ""
        echo "📊 HPA Status:"
        kubectl get hpa -n statista -o wide 2>/dev/null || echo "No HPA configured"
        
        echo ""
        echo "💾 Resource Usage:"
        kubectl top pods -n statista -l app=statista-api 2>/dev/null || echo "Metrics server not available"
        
        echo ""
        echo "📈 Scaling Events:"
        kubectl get events -n statista --sort-by='.lastTimestamp' | grep -E "(HPA|Scaled)" | tail -5
        
        sleep 5
    done
}

# Main execution
case "${5:-stress}" in
    "stress")
        echo "🔥 Running high-load stress test..."
        echo "📈 Target: $RPS requests/second for ${DURATION}s"
        echo "👥 Concurrent users: $CONCURRENT_USERS"
        echo ""
        
        # Generate a sample search query
        SEARCH_DATA='{"query": "statistics data", "limit": 10}'
        
        echo "🎯 Testing search endpoint with high load..."
        hey -z ${DURATION}s -q $RPS -c $CONCURRENT_USERS -m POST -H "Content-Type: application/json" -d "$SEARCH_DATA" "$BASE_URL/find"
        ;;
    "monitor")
        echo "📊 Starting monitoring only..."
        monitor_scaling
        ;;
    *)
        echo "Usage: $0 [BASE_URL] [DURATION] [RPS] [CONCURRENT_USERS] [TEST_TYPE]"
        echo ""
        echo "Parameters:"
        echo "  BASE_URL          - API base URL (default: http://localhost:8000)"
        echo "  DURATION          - Test duration in seconds (default: 30)"
        echo "  RPS               - Requests per second (default: 50)"
        echo "  CONCURRENT_USERS  - Number of concurrent users (default: 20)"
        echo "  TEST_TYPE         - 'stress' or 'monitor'"
        echo ""
        echo "Examples:"
        echo "  $0                                    # Default stress test"
        echo "  $0 http://localhost:8000 60 100 30   # High load test"
        echo "  $0 http://localhost:8000 0 0 0 monitor # Monitor only"
        exit 1
        ;;
esac

# Show final status
echo ""
echo "📊 Final deployment status:"
kubectl get pods -n statista -l app=statista-api

echo ""
echo "📈 HPA status:"
kubectl get hpa -n statista 2>/dev/null || echo "No HPA configured"

echo ""
echo "💡 To monitor scaling in real-time:"
echo "  $0 $BASE_URL 0 0 0 monitor" 