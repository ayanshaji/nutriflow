# ---------------------------------------------------------
# Get the default VPC
# ---------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}


# ---------------------------------------------------------
# Get subnets from the default VPC
# ---------------------------------------------------------

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


# =========================================================
# EKS CLUSTER IAM ROLE
# =========================================================

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}


# EKS Cluster Policy

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


# =========================================================
# EKS CLUSTER
# =========================================================

resource "aws_eks_cluster" "nutriflow" {

  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  version = "1.34"

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}


# =========================================================
# EKS WORKER NODE IAM ROLE
# =========================================================

resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}


# ---------------------------------------------------------
# Worker Node Policy
# ---------------------------------------------------------

resource "aws_iam_role_policy_attachment" "worker_node_policy" {

  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}


# ---------------------------------------------------------
# CNI Policy
# ---------------------------------------------------------

resource "aws_iam_role_policy_attachment" "cni_policy" {

  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


# ---------------------------------------------------------
# ECR Read Policy
# ---------------------------------------------------------

resource "aws_iam_role_policy_attachment" "ecr_pull_policy" {

  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# =========================================================
# EKS MANAGED NODE GROUP
# =========================================================

resource "aws_eks_node_group" "nutriflow" {

  cluster_name = aws_eks_cluster.nutriflow.name

  node_group_name = "${var.cluster_name}-nodes"

  node_role_arn = aws_iam_role.eks_node_role.arn

  subnet_ids = data.aws_subnets.default.ids

  instance_types = [var.node_instance_type]

  scaling_config {

    desired_size = var.node_count

    min_size = 1

    max_size = 3
  }

  depends_on = [

    aws_iam_role_policy_attachment.worker_node_policy,

    aws_iam_role_policy_attachment.cni_policy,

    aws_iam_role_policy_attachment.ecr_pull_policy
  ]
}
