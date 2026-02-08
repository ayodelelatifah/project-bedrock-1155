  terraform {
  backend "s3" {
    bucket       = "bedrock-assets-1155"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
} 