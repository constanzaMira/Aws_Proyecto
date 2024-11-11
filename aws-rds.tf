# Security Group para RDS
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Name = "rds-tic-sg"
  }

  # Regla de entrada: permite solo tráfico desde ciertas IPs o subnets
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.huerta_ecs_sg.id]
  }

  # Regla de salida: permite todas las conexiones de salida
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Grupo de subnets para RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  tags = {
    Name = "rds-tic-subnet-group"
  }
}

resource "aws_db_instance" "huerta_rds" {
  allocated_storage      = 200
  engine                 = "postgres"
  instance_class         = "db.m5.large"
  db_name                = "huerta_db"
  username               = "huerta_tic"
  password               = "lab_tic_v"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  backup_retention_period = 7
  multi_az                = true
  storage_type            = "gp2"
  publicly_accessible     = false
  skip_final_snapshot     = true
  tags = {
    Name = "project-tic-huerta-db"
  }
}