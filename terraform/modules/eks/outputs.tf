# EKS Module Outputs

data "aws_region" "current" {}

output "cluster_id" {
  description = "Name/ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint URL for EKS cluster API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Kubernetes version running on the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster communication"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN used by the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_security_group_id" {
  description = "Security group ID for EKS worker nodes"
  value       = aws_security_group.node.id
}

output "node_iam_role_arn" {
  description = "IAM role ARN for EKS worker nodes"
  value       = aws_iam_role.node.arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.cluster[0].arn : null
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider (without https://)"
  value       = var.enable_irsa ? replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "") : null
}

output "kubectl_config_command" {
  description = "Command to configure kubectl to access this cluster"
  value       = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${aws_eks_cluster.main.name}"
}