# Security Group para el ALB
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.project_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "huerta-alb-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "huerta_alb" {
  name               = "huerta-backend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "huerta-backend-alb"
  }
}

# Target Group para ECS
resource "aws_lb_target_group" "huerta_backend_tg" {
  name        = "huerta-backend-tg"
  port        = 4000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.project_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "huerta-backend-target-group"
  }
}

# Listener HTTP en el ALB
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.huerta_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.huerta_backend_tg.arn
  }
}