variable "project_name" {
  description = "Name of the project (used in resource naming)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC (IP address range)"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones to use (for high availability)"
  type        = list(string)
}

variable "enable_dns_hostnames" {
  description = "Whether to enable DNS hostnames in the VPC"
  type        = bool
}

variable "enable_dns_support" {
  description = "Whether to enable DNS support in the VPC"
  type        = bool
}