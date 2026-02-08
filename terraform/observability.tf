# Install the CloudWatch Observability Add-on
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "amazon-cloudwatch-observability"
}

# Ensure the EKS Node Group has permission to send logs
resource "aws_iam_role_policy_attachment" "node_cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node_group_role.name
}