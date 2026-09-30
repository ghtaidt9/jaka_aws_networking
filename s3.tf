resource "aws_s3_bucket" "microservices" {
  bucket        = local.s3_bucket_name
  force_destroy = true # dev/lab bucket - lets terraform destroy remove objects too
}

resource "aws_s3_bucket_versioning" "microservices" {
  bucket = aws_s3_bucket.microservices.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "microservices" {
  bucket = aws_s3_bucket.microservices.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "microservices" {
  bucket                  = aws_s3_bucket.microservices.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "microservices" {
  bucket = aws_s3_bucket.microservices.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.microservices.arn,
          "${aws_s3_bucket.microservices.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.microservices]

}

resource "aws_s3_bucket_lifecycle_configuration" "microservices" {
  bucket = aws_s3_bucket.microservices.id

  rule {
    id     = "orders-tiering"
    status = "Enabled"
    filter { prefix = "orders/" }

    transition {
      days          = var.s3_ia_transition_days
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = var.s3_glacier_transition_days
      storage_class = "GLACIER"
    }
    noncurrent_version_expiration {
      noncurrent_days = var.s3_noncurrent_version_expiration_days
    }
  }

  rule {
    id     = "payments-tiering"
    status = "Enabled"
    filter { prefix = "payments/" }
    transition {
      days          = var.s3_ia_transition_days
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = var.s3_glacier_transition_days
      storage_class = "GLACIER"
    }
    noncurrent_version_expiration {
      noncurrent_days = var.s3_noncurrent_version_expiration_days
    }
  }
}
