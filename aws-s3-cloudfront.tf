provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "huerta_frontend" {
  bucket = "huerta-frontend-test"
  acl    = "private"

  versioning {
    enabled = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"  # Usando KMS para habilitar Bucket Key
        kms_master_key_id = "alias/aws/s3"
      }
      bucket_key_enabled = true  # Habilita la Bucket Key
    }
  }

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Name = "huerta-frontend-test"
  }
}

resource "aws_s3_bucket_public_access_block" "huerta_frontend_access_block" {
  bucket                  = aws_s3_bucket.huerta_frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_distribution" "huerta_frontend_distribution" {
  origin {
    domain_name = aws_s3_bucket.huerta_frontend.bucket_regional_domain_name
    origin_id   = "S3-huerta-frontend-test"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.huerta_frontend_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-huerta-frontend-test"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_All"
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_identity" "huerta_frontend_identity" {
  comment = "OAI for huerta-frontend-test bucket"
}

resource "aws_s3_bucket_policy" "huerta_frontend_policy" {
  bucket = aws_s3_bucket.huerta_frontend.id
  policy = jsonencode({
    "Version": "2008-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
      {
        "Sid": "AllowCloudFrontServicePrincipal",
        "Effect": "Allow",
        "Principal": {
          "Service": "cloudfront.amazonaws.com"
        },
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::huerta-frontend-test/*",
        "Condition": {
          "StringEquals": {
            "AWS:SourceArn": aws_cloudfront_distribution.huerta_frontend_distribution.arn
          }
        }
      }
    ]
  })
}
