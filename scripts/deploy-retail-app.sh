#!/bin/bash

# Define the namespace
NAMESPACE="retail-app"

echo "🚀 Starting deployment of the Retail Store App..."

# 1. Ensure the namespace exists
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# 2. Install Catalog Service & MySQL
echo "📦 Installing Catalog Service..."
helm install catalog oci://public.ecr.aws/aws-containers/retail-store-sample-catalog-chart:1.4.0 \
  --namespace $NAMESPACE \
  --set mysql.create=true \
  --set app.persistence.provider=mysql \
  --wait

# 3. Install Cart Service & DynamoDB local
echo "📦 Installing Cart Service..."
helm install cart oci://public.ecr.aws/aws-containers/retail-store-sample-cart-chart:1.4.0 \
  --namespace $NAMESPACE \
  --set dynamodb.create=true \
  --set app.persistence.provider=dynamodb \
  --wait

# 4. Install Orders Service, PostgreSQL & RabbitMQ
echo "📦 Installing Orders Service..."
helm install orders oci://public.ecr.aws/aws-containers/retail-store-sample-orders-chart:1.4.0 \
  --namespace $NAMESPACE \
  --set postgresql.create=true \
  --set app.persistence.provider=postgresql \
  --set rabbitmq.create=true \
  --set app.messaging.provider=rabbitmq \
  --wait

# 5. Install Checkout Service & Redis
echo "📦 Installing Checkout Service..."
helm install checkout oci://public.ecr.aws/aws-containers/retail-store-sample-checkout-chart:1.4.0 \
  --namespace $NAMESPACE \
  --set redis.create=true \
  --set app.persistence.provider=redis \
  --wait

# 6. Install UI Service
echo "📦 Installing UI Service..."
helm install ui oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart:1.4.0 \
  --namespace $NAMESPACE \
  --set app.endpoints.catalog=http://catalog:80 \
  --set app.endpoints.carts=http://cart-carts:80 \
  --set app.endpoints.orders=http://orders:80 \
  --set app.endpoints.checkout=http://checkout:80 \
  --wait

echo "✅ Deployment complete!"
echo "------------------------------------------------"
kubectl get pods -n $NAMESPACE