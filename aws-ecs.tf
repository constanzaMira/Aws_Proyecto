# Cluster ECS
resource "aws_ecs_cluster" "huerta_backend_cluster" {
  name = "huerta-backend-cluster-terraform"
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/huerta-backend-terraform"
  retention_in_days = 7  # Cambia esto si quieres mantener los logs por más tiempo
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
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",  # Autenticación para ECR y CloudWatch
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",             # Acceso solo lectura a ECR
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",                           # Para logs en CloudWatch
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"                              # Para acceso a S3 si es necesario
  ]
}

# IAM Role para ECS Task (acceso a servicios como DynamoDB, IoT, Timestream)
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
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",       # Para DynamoDB
    "arn:aws:iam::aws:policy/AmazonTimestreamFullAccess",     # Para Timestream
    "arn:aws:iam::aws:policy/AWSIoTFullAccess"               # Para AWS IoT
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
    image     = "043309344191.dkr.ecr.${var.region}.amazonaws.com/huerta-backend:latest"  # Imagen en ECR
    cpu       = 0
    memory    = 1024
    essential = true

    portMappings = [{
      containerPort = 4000 
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "DB_HOST"
        value = aws_db_instance.huerta_rds.endpoint
      },
      {
        name  = "DB_PORT"
        value = "5432"
      },
      {
        name  = "DB_USER"
        value = "huerta_tic"
      },
      {
        name  = "DB_PASSWORD"
        value = "lab_tic_v"
      },
      {
        name  = "DB_NAME"
        value = "huerta_db"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

# Servicio de ECS
resource "aws_ecs_service" "huerta_backend_service" {
  name            = "huerta-backend-service-terraform"
  cluster         = aws_ecs_cluster.huerta_backend_cluster.id
  task_definition = aws_ecs_task_definition.huerta_backend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

load_balancer {
  target_group_arn = aws_lb_target_group.huerta_backend_tg.arn
  container_name   = "huerta-container"  # Nombre del contenedor en la definición de la tarea
  container_port   = 4000                # Puerto expuesto por el contenedor
}

network_configuration {
  subnets          = [
    aws_subnet.public_subnet_1.id,  # Subnet pública
    aws_subnet.public_subnet_2.id,  # Subnet pública

  ]
  security_groups  = [aws_security_group.huerta_ecs_sg.id]
  assign_public_ip = true  # Asignar IP pública para acceder a ECR
}

  # Dependencias explícitas en la configuración
  depends_on = [
    aws_lb_listener.http_listener,            # Listener del ALB
    aws_ecs_task_definition.huerta_backend_task # Task Definition
  ]
}
