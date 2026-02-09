region       = "us-east-1"
project_name = "project-bedrock"

# Networking
vpc_cidr        = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]

# S3 & IAM
assets_bucket_name = "bedrock-assets-1155"
gorgeous_user_arn  = "arn:aws:iam::229658172170:user/gorgeous"

# Requirements-compliant Tags
common_tags = {
  Project   = "Bedrock"
  ManagedBy = "Terraform"
  cluster_version = "1.31"
}