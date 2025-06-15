#!/bin/bash
set -e

echo "🚀 Starting Smart Cart deployment..."

# Check if required tools are installed
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed." >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is required but not installed." >&2; exit 1; }

# Set variables
ENVIRONMENT=${1:-dev}
AWS_REGION=${AWS_REGION:-us-west-2}
CLUSTER_NAME=maxsaver-pro-${ENVIRONMENT}-eks-cluster

echo "📋 Deploying to environment: $ENVIRONMENT"
echo "🌍 AWS Region: $AWS_REGION"
echo "☸️  EKS Cluster: $CLUSTER_NAME"

# Update kubeconfig
echo "⚙️  Configuring kubectl..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Apply Kubernetes manifests
echo "☸️  Deploying to Kubernetes..."

# Create namespace
kubectl apply -f kubernetes/namespace.yaml

# Apply configurations
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/secrets.yaml

# Deploy database and cache
kubectl apply -f kubernetes/postgres-deployment.yaml
kubectl apply -f kubernetes/redis-deployment.yaml

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/smart-cart-postgres -n smart-cart

# Deploy backend application
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/ingress.yaml
kubectl apply -f kubernetes/hpa.yaml

# Deploy monitoring
kubectl apply -f kubernetes/monitoring.yaml

# Wait for backend deployment to be ready
echo "⏳ Waiting for backend deployment to be ready..."
kubectl rollout status deployment/smart-cart-backend -n smart-cart --timeout=300s

# Get deployment status
echo "📊 Deployment Status:"
kubectl get pods -n smart-cart
kubectl get services -n smart-cart
kubectl get ingress -n smart-cart

# Get external URL
EXTERNAL_IP=$(kubectl get ingress smart-cart-ingress -n smart-cart -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if [ -n "$EXTERNAL_IP" ]; then
    echo "🌐 Application URL: https://$EXTERNAL_IP"
else
    echo "⏳ External IP is being assigned..."
fi

# Run health check
echo "🏥 Running health check..."
sleep 30

# Check if pods are running
RUNNING_PODS=$(kubectl get pods -n smart-cart --field-selector=status.phase=Running --no-headers | wc -l)
TOTAL_PODS=$(kubectl get pods -n smart-cart --no-headers | wc -l)

if [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ]; then
    echo "✅ All pods are running successfully!"
    echo "🎉 Smart Cart deployment complete!"
    echo ""
    echo "📱 Update your iOS app baseURL to: https://$EXTERNAL_IP"
    echo "📊 Monitor with: kubectl get pods -n smart-cart"
    echo "🔍 View logs: kubectl logs -f deployment/smart-cart-backend -n smart-cart"
else
    echo "⚠️  Some pods are not running. Check status:"
    kubectl get pods -n smart-cart
    echo "🔍 Check logs: kubectl logs -f deployment/smart-cart-backend -n smart-cart"
fi

echo ""
echo "🚀 Smart Cart is now live!" 