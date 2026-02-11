################################################################################
# 1. IAM ROLE: EKS Control Plane
################################################################################

resource "aws_iam_role" "eks_cluster_role" {
  # Matching legacy name to prevent cluster replacement
  name = "project-bedrock-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

################################################################################
# 2. CLOUDWatch LOGGING: Infrastructure & Application logs
################################################################################

# Explicitly defining the log group ensures "Logging is setup" for the instructor
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/project-bedrock-cluster/cluster"
  retention_in_days = 7
  tags              = var.common_tags
}

################################################################################
# 3. EKS CLUSTER: Control Plane
################################################################################

resource "aws_eks_cluster" "main" {
  name     = "project-bedrock-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version

  # Sends internal EKS logs to the CloudWatch group created above
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
    aws_cloudwatch_log_group.eks_cluster
  ]

  tags = var.common_tags
}

################################################################################
# 4. CLUSTER ACCESS: Admin Rights for Instructor (Gorgeous)
################################################################################

resource "aws_eks_access_entry" "admin_user" {
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = var.gorgeous_user_arn
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_policy" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.gorgeous_user_arn

  access_scope {
    type = "cluster"
  }
}

################################################################################
# 5. IAM ROLE: EKS Node Group (The Workers)
################################################################################

resource "aws_iam_role" "node_group_role" {
  name = "project-bedrock-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group_role.name
}

# Requirement: Fixed application logging for components
resource "aws_iam_role_policy_attachment" "node_CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node_group_role.name
}

################################################################################
# 6. MANAGED NODE GROUP: The EC2 Instances
################################################################################

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "project-bedrock-node-group"
  node_role_arn   = aws_iam_role.node_group_role.arn
  
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = ["t3.small"]
  version         = var.cluster_version

  scaling_config {
    desired_size = 3
    max_size     = 4
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_CloudWatchAgentServerPolicy
  ]

  tags = var.common_tags
}