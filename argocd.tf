# =========================================================
# EKS CLUSTER INFORMATION
# =========================================================

data "aws_eks_cluster" "nutriflow" {
  name = aws_eks_cluster.nutriflow.name
}

data "aws_eks_cluster_auth" "nutriflow" {
  name = aws_eks_cluster.nutriflow.name
}


# =========================================================
# HELM PROVIDER
# Connect Terraform to the newly created EKS cluster
# =========================================================

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.nutriflow.endpoint
    cluster_ca_certificate = base64decode(
      data.aws_eks_cluster.nutriflow.certificate_authority[0].data
    )
    token = data.aws_eks_cluster_auth.nutriflow.token
  }
}


# =========================================================
# ARGO CD
# =========================================================

resource "helm_release" "argocd" {

  name = "argocd"

  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"

  chart  = "argo-cd"
  version = "9.4.2"

  depends_on = [
    aws_eks_node_group.nutriflow
  ]
}
