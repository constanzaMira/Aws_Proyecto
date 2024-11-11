# Repositorio ECR
resource "aws_ecr_repository" "huerta_backend" {
  name                 = "huerta-backend"
  image_tag_mutability = "MUTABLE" # Cambia a "IMMUTABLE" si deseas que las etiquetas sean inmutables
  encryption_configuration {
    encryption_type = "AES256" # Tipo de encriptación
  }
  tags = {
    Name = "huerta-backend-repo"
  }
}

# Política de permisos para ECR, para permitir acceso desde ECS y otros servicios
resource "aws_ecr_repository_policy" "huerta_backend_policy" {
  repository = aws_ecr_repository.huerta_backend.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowECS",
        Effect    = "Allow",
        Principal = "*",
        Action    = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid       = "AllowPushFromIAMUser",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/huerta-user"
        },
        Action    = [
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}

# Output para el URI del repositorio
output "ecr_repository_url" {
  value = aws_ecr_repository.huerta_backend.repository_url
  description = "URI del repositorio ECR de huerta-backend"
}

# Obtener el ID de la cuenta de AWS
data "aws_caller_identity" "current" {}