# IAM User Definition
resource "aws_iam_user" "huerta_user" {
  name = "huerta-user"
}

# Attach Managed Policies to the User
resource "aws_iam_user_policy_attachment" "huerta_user_policies" {
  count = length(local.managed_policies)

  user       = aws_iam_user.huerta_user.name
  policy_arn = local.managed_policies[count.index]
}

# List of Managed Policies
locals {
  managed_policies = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchFullAccessV2",
    "arn:aws:iam::aws:policy/IAMFullAccess"
  ]
}
