################################################################################
# 1. IAM ROLE: EKS Control Plane (The Brain)
################################################################################

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.project_name}-cluster-role"

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

# Attach policies before cluster creation
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

################################################################################
# 2. EKS CLUSTER: Control Plane
################################################################################

resource "aws_eks_cluster" "main" {
  name     = "project-${lower(var.project_name)}-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version

  # Requirement: Send logs to CloudWatch
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # Requirement: Enable API Authentication for Access Entries
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller
  ]

  tags = var.common_tags
}

################################################################################
# 3. CLUSTER ACCESS: Admin Rights for Gorgeous User
################################################################################

/* resource "aws_eks_access_entry" "admin_user" {
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = var.gorgeous_user_arn
  type              = "STANDARD"
}
*/

resource "aws_eks_access_policy_association" "admin_policy" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.gorgeous_user_arn

  access_scope {
    type = "cluster"
  }
}

################################################################################
# 4. IAM ROLE: EKS Node Group (The Workers)
################################################################################

resource "aws_iam_role" "node_group_role" {
  name = "${var.project_name}-node-group-role"

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

# Requirement: Allow workers to connect, pull images, and manage networking
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

################################################################################
# 5. MANAGED NODE GROUP: The EC2 Instances
################################################################################

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = aws_iam_role.node_group_role.arn
  
  # Requirement: Nodes in private subnets
  subnet_ids      = aws_subnet.private[*].id

  # Requirement: t3.small, managed by AWS
  instance_types = ["t3.small"]
  version        = var.cluster_version

  # Requirement: Autoscaling (2, 2, 2)
  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure IAM policies exist until nodes are deleted
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = var.common_tags
}

# 5. EKS Access Entry for the Dev User
resource "aws_eks_access_entry" "dev_viewer_entry" {
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = aws_iam_user.dev_viewer.arn
  type              = "STANDARD"

  # Adding tags for resource tracking
  tags = merge(var.common_tags, {
    Name = "bedrock-dev-viewer-access"
    Role = "Developer-ReadOnly"
  })
}

# 6. Associate the "View" Policy (Layer 2)
resource "aws_eks_access_policy_association" "dev_viewer_policy" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  principal_arn = aws_iam_user.dev_viewer.arn

  access_scope {
    type = "cluster"
  }
}