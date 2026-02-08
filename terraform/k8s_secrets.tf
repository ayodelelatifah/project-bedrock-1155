# 1. KUBERNETES PROVIDER
# This uses the EKS cluster details to authenticate Terraform to Kubernetes.
provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
    command     = "aws"
  }
}

# 2. KUBERNETES NAMESPACE
# Creates the "retail-app" home for your microservices.
resource "kubernetes_namespace" "retail_app" {
  metadata {
    name = "retail-app"
  }
  
  # Ensure the cluster nodes are healthy before trying to talk to the API
  depends_on = [aws_eks_node_group.main]
}

# 3. KUBERNETES SECRET
# Injects the RDS hostnames and credentials into the "retail-app" namespace.
resource "kubernetes_secret" "rds_credentials" {
  metadata {
    name      = "rds-db-credentials"
    namespace = kubernetes_namespace.retail_app.metadata[0].name 
  }

  # We use .address to get the DNS name (Host) without the :port suffix
  data = {
    catalog_db_host = aws_db_instance.catalog_db.address
    orders_db_host  = aws_db_instance.orders_db.address
    username        = "admin"
    password        = "password123"
  }

  type = "Opaque"

  # Explicit dependency to ensure the namespace exists first
  depends_on = [kubernetes_namespace.retail_app]
}