# Terraform Outputs
# These values are displayed after 'terraform apply' completes

# ═══════════════════════════════════════════════════════════
# VPC Outputs
# ═══════════════════════════════════════════════════════════

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# ═══════════════════════════════════════════════════════════
# EKS Outputs
# ═══════════════════════════════════════════════════════════

output "eks_cluster_id" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = module.eks.cluster_version
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = module.eks.kubectl_config_command
}

# Output the role ARN - you'll need this for GitHub Actions
output "github_actions_role_arn" {
  description = "ARN to configure in GitHub Actions workflow"
  value       = module.github_oidc.role_arn
  sensitive   = false  # Not sensitive - it's just an identifier
}

# ═══════════════════════════════════════════════════════════
# Connection Instructions
# ═══════════════════════════════════════════════════════════

output "connection_instructions" {
  description = "Instructions for connecting to the EKS cluster"
  value       = <<-EOT
  
  ╔════════════════════════════════════════════════════════════╗
  ║  🎉 INFRASTRUCTURE DEPLOYED SUCCESSFULLY!                  ║
  ╚════════════════════════════════════════════════════════════╝
  
  📋 NEXT STEPS:
  
  1️⃣  Configure kubectl to access your cluster:
     ${module.eks.kubectl_config_command}
  
  2️⃣  Verify cluster access:
     kubectl cluster-info
     kubectl get nodes
  
  3️⃣  Wait for nodes to be Ready (may take 2-3 minutes):
     kubectl get nodes --watch
  
  4️⃣  Create the production namespace:
     kubectl create namespace production
  
  📊 CLUSTER INFORMATION:
     • Cluster Name: ${module.eks.cluster_id}
     • Kubernetes Version: ${module.eks.cluster_version}
     • Region: ${var.aws_region}
     • Worker Nodes: ${var.eks_node_desired_size} (min: ${var.eks_node_min_size}, max: ${var.eks_node_max_size})
     • Instance Type: ${join(", ", var.eks_node_instance_types)}
  
  🌐 NETWORK INFORMATION:
     • VPC ID: ${module.vpc.vpc_id}
     • VPC CIDR: ${module.vpc.vpc_cidr}
     • Public Subnets: ${length(module.vpc.public_subnet_ids)}
     • Private Subnets: ${length(module.vpc.private_subnet_ids)}
  
  💰 ESTIMATED MONTHLY COST:
     • EKS Control Plane: $73.00
     • Worker Nodes (2x t3.medium): ~$60.00
     • NAT Gateway: ~$32.00
     • Data Transfer & Logs: ~$10-20
     • TOTAL: ~$175-185/month
  
  ⚠️  IMPORTANT: Don't forget to destroy resources when done:
     terraform destroy
  
  EOT
}