# Crear el grupo de logs en CloudWatch
resource "aws_cloudwatch_log_group" "huerta_log_group" {
  name              = "/ecs/huerta-backend-terraform"
  retention_in_days = 7  # Retención de logs en días; ajusta según necesites
}

# Cluster ECS
resource "aws_ecs_cluster" "huerta_backend_cluster" {
  name = "huerta-backend-cluster-terraform"
}

# IAM Role para ECS Task Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-terraform-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}

# IAM Role para ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-terraform-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonTimestreamFullAccess",
    "arn:aws:iam::aws:policy/AWSIoTFullAccess"
  ]
}

# Definición de la tarea ECS
resource "aws_ecs_task_definition" "huerta_backend_task" {
  family                   = "huerta-backend-task-terraform"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "huerta-container"
    image     = "043309344191.dkr.ecr.${var.region}.amazonaws.com/huerta-backend:latest"
    cpu       = 0
    memory    = 1024
    essential = true

    portMappings = [{
      containerPort = 4000
      hostPort      = 4000
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.huerta_log_group.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
  
  # Depende del grupo de logs
  depends_on = [aws_cloudwatch_log_group.huerta_log_group]
}

# Servicio de ECS
resource "aws_ecs_service" "huerta_backend_service" {
  name            = "huerta-backend-service-terraform"
  cluster         = aws_ecs_cluster.huerta_backend_cluster.id
  task_definition = aws_ecs_task_definition.huerta_backend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]  # Usando subnets públicas
    security_groups  = [aws_security_group.huerta_ecs_sg.id]  # Security group configurado
    assign_public_ip = true
  }

  depends_on = [aws_ecs_task_definition.huerta_backend_task]  # Asegura que el task definition esté listo antes del servicio
}