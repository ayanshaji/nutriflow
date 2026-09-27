output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.nutriflow.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.nutriflow.endpoint
}

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = helm_release.argocd.namespace
}
