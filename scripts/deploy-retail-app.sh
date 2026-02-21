#!/bin/bash

# Capture RDS endpoints passed from the GitHub Action
CATALOG_ENDPOINT=$1
ORDERS_ENDPOINT=$2

# Define the namespace
NAMESPACE="retail-app"

echo "🚀 Starting deployment with RDS Integration..."

# 1. Ensure the namespace exists
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# 2. Install Catalog Service (MySQL RDS)
echo "📦 Installing Catalog Service linked to RDS..."
helm upgrade --install catalog oci://public.ecr.aws/aws-containers/retail-store-sample-catalog-chart:1.4.0 \
  --namespace $NAMESPACE \
  --set mysql.create=false \
  --set app.persistence.provider=mysql \
  --set app.database.endpoint=$CATALOG_ENDPOINT \
  --set app.database.user=admin \
  --set app.database.name=catalog \
  --wait

# 3. Install Orders Service (PostgreSQL RDS)
echo "📦 Installing Orders Service linked to RDS..."
helm upgrade --install orders oci://public.ecr.aws/aws-containers/retail-store-sample-orders-chart:1.4.0 \
  --namespace $NAMESPACE \
  --set postgresql.create=false \
  --set app.persistence.provider=postgresql \
  --set app.database.endpoint=$ORDERS_ENDPOINT \
  --set app.database.user=admin \
  --set app.database.name=orders \
  --set rabbitmq.create=true \
  --set app.messaging.provider=rabbitmq \
  --wait
  
# 4. Install Cart Service
echo "📦 Installing Cart Service..."
helm upgrade --install cart oci://public.ecr.aws/aws-containers/retail-store-sample-cart-chart:1.4.0 \
  --namespace $NAMESPACE \
  --set dynamodb.create=true \
  --set app.persistence.provider=dynamodb \
  --wait

# 5. Install Checkout Service
echo "📦 Installing Checkout Service..."
helm upgrade --install checkout oci://public.ecr.aws/aws-containers/retail-store-sample-checkout-chart:1.4.0 \
  --namespace $NAMESPACE \
  --set redis.create=true \
  --set app.persistence.provider=redis \
  --wait

# 6. Install UI Service
echo "📦 Installing UI Service..."
helm upgrade --install ui oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart:1.4.0 \
  --namespace $NAMESPACE \
  --set app.endpoints.catalog=http://catalog:80 \
  --set app.endpoints.carts=http://cart-carts:80 \
  --set app.endpoints.orders=http://orders:80 \
  --set app.endpoints.checkout=http://checkout:80 \
  --set service.type=LoadBalancer \
  --wait

echo "✅ Deployment complete! RDS instances are now utilized."
echo "------------------------------------------------"
kubectl get pods -n $NAMESPACE