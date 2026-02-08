# 1. Create the IAM User
resource "aws_iam_user" "dev_viewer" {
  name = "bedrock-dev-view"
  tags = var.common_tags
}

# 2. Console Access: Attach AWS Managed ReadOnlyAccess Policy
# This fulfills the "Console Access" requirement for viewing resources.
resource "aws_iam_user_policy_attachment" "dev_readonly" {
  user       = aws_iam_user.dev_viewer.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# 3. Custom Policy: S3 Bucket Upload + EKS Describe
# Allows developer to upload to the specific assets bucket for Lambda testing
# and permits EKS Describe so they can generate their kubeconfig.
resource "aws_iam_user_policy" "dev_custom_access" {
  name = "bedrock-dev-custom-access"
  user = aws_iam_user.dev_viewer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.state_bucket.id}/*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "eks:DescribeCluster"
        ]
        Resource = aws_eks_cluster.main.arn
      }
    ]
  })
}

# 4. Create Programmatic Access Keys (The Deliverable)
resource "aws_iam_access_key" "dev_viewer_key" {
  user = aws_iam_user.dev_viewer.name
}