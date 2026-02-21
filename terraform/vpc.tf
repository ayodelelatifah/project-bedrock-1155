################################################################################
# VPC & NETWORKING - RECOVERY SHEET
################################################################################

# 1. The VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, { Name = "project-bedrock-vpc" })
}

# 2. Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.common_tags, { Name = "${var.project_name}-igw" })
}

# 3. Public Subnets
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = "${var.region}${count.index == 0 ? "a" : "b"}"
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, { 
    Name                     = "project-bedrock-public-${count.index}" 
    "kubernetes.io/role/elb" = "1"
  })
}

# 4. Private Subnets
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = "${var.region}${count.index == 0 ? "a" : "b"}"

  tags = merge(var.common_tags, { 
    Name                              = "project-bedrock-private-${count.index}" 
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# 5. Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(var.common_tags, { Name = "${var.project_name}-nat-eip" })
}

# 6. NAT Gateway
resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = merge(var.common_tags, { Name = "${var.project_name}-nat-gw" })
}

# 7. Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(var.common_tags, { Name = "${var.project_name}-public-rt" })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
  }
  tags = merge(var.common_tags, { Name = "${var.project_name}-private-rt" })
}

# 8. Route Table Associations
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}