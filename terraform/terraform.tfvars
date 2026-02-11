region       = "us-east-1"
project_name = "barakat-2025-capstone"

# Networking
vpc_cidr        = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

# S3 & IAM
assets_bucket_name = "bedrock-assets-1155"
gorgeous_user_arn  = "arn:aws:iam::229658172170:user/gorgeous"

# EKS Version (Explicit variable)
cluster_version = "1.31"

# Requirements-compliant Tags
common_tags = {
  Project   = "barakat-2025-capstone"
  ManagedBy = "Terraform"
  # You can keep it here too if you want it as a tag!
  Version   = "1.31" 
}