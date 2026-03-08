# Terraform Configuration for SRE Lab Project
# This is the main entry point for our infrastructure

# Configure Terraform itself
terraform {
  required_version = ">= 1.0" # Requires Terraform 1.0 or newer

  required_providers {
    aws = {
      source  = "hashicorp/aws" # Use AWS provider
      version = "~> 5.0"        # Version 5.x (allows minor updates)
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region # Which AWS region to use (from variables)

  # Default tags applied to ALL resources we create
  default_tags {
    tags = {
      Project     = "SRE-Lab"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

# Create VPC using our custom module
module "vpc" {
  source = "./modules/vpc" # Path to VPC module

  # Pass variables to the VPC module
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr

  # Availability zones for high availability
  availability_zones = var.availability_zones

  # Enable DNS for service discovery
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # No need for tags here - default_tags handles it! ✅
}


# ═══════════════════════════════════════════════════════════
# EKS MODULE - Kubernetes Cluster
# ═══════════════════════════════════════════════════════════

module "eks" {
  source = "./modules/eks"

  # Basic configuration
  project_name    = var.project_name
  environment     = var.environment
  cluster_version = var.eks_cluster_version

  # Network configuration (from VPC module outputs!)
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # Worker node configuration
  node_instance_types = var.eks_node_instance_types
  node_desired_size   = var.eks_node_desired_size
  node_min_size       = var.eks_node_min_size
  node_max_size       = var.eks_node_max_size
  node_disk_size      = var.eks_node_disk_size

  # Access configuration
  cluster_endpoint_public_access       = var.eks_cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.eks_cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.eks_cluster_endpoint_public_access_cidrs

  # Features
  enable_irsa               = var.eks_enable_irsa
  cluster_enabled_log_types = var.eks_cluster_enabled_log_types
  enable_cluster_encryption = var.eks_enable_cluster_encryption

  # Explicit dependency on VPC
  depends_on = [module.vpc]
}