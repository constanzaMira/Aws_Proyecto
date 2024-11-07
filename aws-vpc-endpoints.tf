# VPC Endpoint para ECR API
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.project_vpc.id
  service_name      = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  security_group_ids = [aws_security_group.huerta_ecs_sg.id]
  tags = {
    Name = "project-tic-ecr-api-endpoint"
  }
}

# VPC Endpoint para ECR Docker Registry (DKR)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.project_vpc.id
  service_name      = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  security_group_ids = [aws_security_group.huerta_ecs_sg.id]
  tags = {
    Name = "project-tic-ecr-dkr-endpoint"
  }
}

# VPC Endpoint para CloudWatch Logs
resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id            = aws_vpc.project_vpc.id
  service_name      = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  security_group_ids = [aws_security_group.huerta_ecs_sg.id]
  tags = {
    Name = "project-tic-cloudwatch-logs-endpoint"
  }
}

# VPC Endpoint para S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.project_vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.private_route_table_1.id, aws_route_table.private_route_table_2.id]
  tags = {
    Name = "project-s3-endpoint"
  }
}