#!/bin/bash

NAMESPACE="retail-app"

echo "⚠️  Starting cleanup of the Retail Store App..."

# 1. Uninstall Helm releases
echo "🗑️  Uninstalling Helm charts..."
helm uninstall ui checkout orders cart catalog -n $NAMESPACE || true

# 2. Delete the namespace (removes all leftover pods, services, and secrets)
echo "🔥 Deleting the $NAMESPACE namespace..."
kubectl delete namespace $NAMESPACE --wait=true

echo "✅ Cleanup complete! Your cluster is now clean."