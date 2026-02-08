# 1. DB SUBNET GROUP: Places RDS in your Private Subnets
resource "aws_db_subnet_group" "database_subnets" {
  name       = "${lower(var.project_name)}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(var.common_tags, { Name = "Main DB Subnet Group" })
}

# 2. SECURITY GROUP: The "Firewall" for your DBs
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow traffic from EKS cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from EKS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_eks_cluster.main.vpc_config[0].cluster_security_group_id]
  }

  ingress {
    description     = "PostgreSQL from EKS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_eks_cluster.main.vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}

# 3. RDS INSTANCES: Managed DBs

# MySQL for Catalog Service
resource "aws_db_instance" "catalog_db" {
  allocated_storage      = 20
  db_name                = "catalogdb"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro" 
  username               = "admin"
  password               = "password123" 
  db_subnet_group_name   = aws_db_subnet_group.database_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  
  tags = merge(var.common_tags, { Name = "Catalog-DB" })
}

# PostgreSQL for Orders Service
resource "aws_db_instance" "orders_db" {
  allocated_storage      = 20
  db_name                = "ordersdb"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "password123"
  db_subnet_group_name   = aws_db_subnet_group.database_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = merge(var.common_tags, { Name = "Orders-DB" })
}