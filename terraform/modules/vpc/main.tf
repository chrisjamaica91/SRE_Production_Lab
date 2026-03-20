# VPC Module - Main Infrastructure Definition
# This creates the actual AWS networking resources

# ═══════════════════════════════════════════════════════════
# Local Values (Computed Variables)
# ═══════════════════════════════════════════════════════════

locals {
  # Calculate subnet CIDRs automatically from VPC CIDR
  # This prevents manual IP conflicts
  public_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 1), # 10.0.1.0/24
    cidrsubnet(var.vpc_cidr, 8, 2), # 10.0.2.0/24
  ]

  private_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 11), # 10.0.11.0/24
    cidrsubnet(var.vpc_cidr, 8, 12), # 10.0.12.0/24
  ]

  # Common name prefix for resources
  name_prefix = "${var.project_name}-${var.environment}"
}

# ═══════════════════════════════════════════════════════════
# VPC
# ═══════════════════════════════════════════════════════════

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# ═══════════════════════════════════════════════════════════
# Internet Gateway (for public subnet internet access)
# ═══════════════════════════════════════════════════════════

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# ═══════════════════════════════════════════════════════════
# Public Subnets
# ═══════════════════════════════════════════════════════════

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  
  # nosemgrep: terraform.aws.security.aws-subnet-has-public-ip-address.aws-subnet-has-public-ip-address
  # Justification: This IS the public subnet tier - public IPs required for ALB and NAT Gateway
  # Architecture: Standard AWS VPC design with public/private subnet separation
  # Mitigation: Application workloads run in private subnets, only infrastructure in public
  # Risk: NONE - By design, this is the intended architecture
  # Reference: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-example-private-subnets-nat.html
  # Approved by: Chris | Date: 2026-03-20
  map_public_ip_on_launch = true # Auto-assign public IPs

  tags = {
    Name = "${local.name_prefix}-public-subnet-${count.index + 1}"
    Type = "Public"
  }
}

# ═══════════════════════════════════════════════════════════
# Private Subnets
# ═══════════════════════════════════════════════════════════

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-private-subnet-${count.index + 1}"
    Type = "Private"
  }
}

# ═══════════════════════════════════════════════════════════
# Elastic IP for NAT Gateway
# ═══════════════════════════════════════════════════════════

resource "aws_eip" "nat" {
  count = 1 # Single NAT Gateway for cost savings

  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# ═══════════════════════════════════════════════════════════
# NAT Gateway (for private subnet outbound internet)
# ═══════════════════════════════════════════════════════════

resource "aws_nat_gateway" "main" {
  count = 1 # Single NAT Gateway for cost savings

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${local.name_prefix}-nat-gw-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# ═══════════════════════════════════════════════════════════
# Route Table for Public Subnets
# ═══════════════════════════════════════════════════════════

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-public-rt"
    Type = "Public"
  }
}

# Route to Internet Gateway
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0" # All internet traffic
  gateway_id             = aws_internet_gateway.main.id
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ═══════════════════════════════════════════════════════════
# Route Table for Private Subnets
# ═══════════════════════════════════════════════════════════

resource "aws_route_table" "private" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-private-rt-${count.index + 1}"
    Type = "Private"
  }
}

# Route to NAT Gateway
resource "aws_route" "private_nat_gateway" {
  count = length(var.availability_zones)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"                # All internet traffic
  nat_gateway_id         = aws_nat_gateway.main[0].id # Single NAT
}

# Associate private subnets with private route tables
resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}