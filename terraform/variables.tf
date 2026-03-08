# Variables for SRE Lab Infrastructure
# These define what inputs our infrastructure accepts

# ═══════════════════════════════════════════════════════════
# General Variables
# ═══════════════════════════════════════════════════════════

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project (used in resource naming)"
  type        = string
  default     = "sre-lab"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "owner" {
  description = "Owner of the infrastructure (for tagging)"
  type        = string
  default     = "chris"
}

# ═══════════════════════════════════════════════════════════
# Network Variables
# ═══════════════════════════════════════════════════════════

variable "vpc_cidr" {
  description = "CIDR block for VPC (IP address range)"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones to use (for high availability)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

# ═══════════════════════════════════════════════════════════
# Feature Flags
# ═══════════════════════════════════════════════════════════

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway (cheaper but less HA)"
  type        = bool
  default     = true # Set false for production (one per AZ)
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway for VPN connections"
  type        = bool
  default     = false # We don't need this for now
}

variable "enable_dns_hostnames" {
  description = "Whether to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Whether to enable DNS support in the VPC"
  type        = bool
  default     = true
}


# ═══════════════════════════════════════════════════════════
# EKS Variables
# ═══════════════════════════════════════════════════════════

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "List of EC2 instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.micro"]  # Free tier eligible: 750 hrs/month for first 12 months
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS worker nodes"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS worker nodes"
  type        = number
  default     = 2  # Reduced to minimize vCPU quota needs
}

variable "eks_node_disk_size" {
  description = "Disk size for EKS worker nodes (GB)"
  type        = number
  default     = 20
}

variable "eks_cluster_endpoint_public_access" {
  description = "Enable public access to EKS cluster API endpoint"
  type        = bool
  default     = true
}

variable "eks_cluster_endpoint_private_access" {
  description = "Enable private access to EKS cluster API endpoint"
  type        = bool
  default     = true
}

variable "eks_cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks that can access the public EKS endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA)"
  type        = bool
  default     = true
}

variable "eks_cluster_enabled_log_types" {
  description = "List of control plane log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "eks_enable_cluster_encryption" {
  description = "Enable envelope encryption of Kubernetes secrets with KMS"
  type        = bool
  default     = false
}