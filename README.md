🚀 Project Bedrock: Full-Stack EKS, RDS & Serverless Architecture
This repository contains the complete Infrastructure-as-Code (IaC) and application deployment for a retail microservices store, including an automated serverless asset processor.

🏗️ Phase A: Core Infrastructure (Terraform)
The foundation was built using Terraform to ensure a secure, private environment.

Networking: Created a VPC in us-east-1 with isolated public and private subnets.

Database Provisioning:

MySQL: Created for the catalog service on port 3306.

PostgreSQL: Created for the orders service on port 5432.

Security Groups: Defined rds_sg (ID: sg-0704185facf0ccf82) which strictly allows ingress from the EKS cluster security group.

🚢 Phase B: EKS Cluster & App Deployment
Managed Kubernetes was used to orchestrate the retail store microservices.

EKS Connection: Linked local environment to the cluster using: aws eks update-kubeconfig --region us-east-1 --name project-bedrock-cluster.

Namespace: Isolated the application in the retail-app namespace.

Services: Deployed the ui, orders, and catalog pods as ClusterIP to maintain a private internal network.

🧪 Phase C: Verification & Connectivity
Proved the internal network path by "pivoting" from within the cluster.

Bridge Pod: Launched a temporary mysql-test pod to bypass the private subnet restriction.

Login Test: Successfully authenticated to the RDS MySQL endpoint from inside the cluster.

Status Check: Verified all microservices were running and listening on port 80.

🌟 Phase D: Serverless (Lambda & S3)
Implemented an event-driven "Asset Processor" to handle retail store images/files.

S3 Bucket: Created bedrock-assets-1155 for storage with versioning enabled.

Lambda Function: Deployed bedrock-asset-processor using a ZIP archive of the lambda_function.py code.

The Trigger: Configured an S3 Event Notification to trigger the Lambda whenever a new file is uploaded to the bucket.

IAM Role: Created bedrock-asset-processor-role to allow the Lambda to write logs to CloudWatch.

🌐 Phase E: Application Access
To view the store locally without a public LoadBalancer:

Tunnel: kubectl port-forward svc/ui 8080:80 -n retail-app

URL: http://localhost:8080

✅ Phase F: Grading & Infrastructure Data
The following data was exported to grading.json for automated verification:

EKS Cluster: project-bedrock-cluster.

VPC ID: vpc-0250d4faa3278555c.

IAM User: bedrock-dev-view (Access Key: AKIATK6FRTMFFDPUMKML).

🛠️ Tech Stack
IaC: Terraform.

Compute: Amazon EKS & AWS Lambda.

Database: Amazon RDS (MySQL & Postgres).

CI/CD: GitHub Actions (terraform-ci-cd.yml).
