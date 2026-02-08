terraform {
  required_version = ">= 1.14.0"

   required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  # This ensures ALL resources get the mandatory tag
  default_tags {
    tags = {
      Project = "Bedrock"
    }
  }
}