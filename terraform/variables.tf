variable "region" {
  description = "AWS Region"
  type        = string
}

variable "project_name" {
  description = "Name of the project for naming resources"
  type        = string
  default     = "project-bedrock"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}

variable "common_tags" {
  description = "Required capstone metadata"
  type        = map(string)
  default     = {
    Project = "capstone-barakat-2025"
    Owner   = "Barakat"
    Version = "1.31"
}
}
variable "assets_bucket_name" {
  description = "Name of the S3 bucket for assets and state"
  type        = string
}

variable "gorgeous_user_arn" {
  description = "The ARN for the IAM user gorgeous"
  type        = string
}

variable "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}