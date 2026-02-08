output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = aws_eks_cluster.main.name
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "configure_kubectl" {
  description = "Command to update your kubeconfig locally"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.main.name}"
}

output "dev_access_key_id" {
  value = aws_iam_access_key.dev_viewer_key.id
}

output "dev_secret_access_key" {
  value     = aws_iam_access_key.dev_viewer_key.secret
  sensitive = true
}

output "catalog_db_endpoint" {
  value = aws_db_instance.catalog_db.endpoint
  description = "Connection string for the Catalog service"
}

output "orders_db_endpoint" {
  value = aws_db_instance.orders_db.endpoint
  description = "Connection string for the Orders service"
}

output "rds_security_group_id" {
  value = aws_security_group.rds_sg.id
}
