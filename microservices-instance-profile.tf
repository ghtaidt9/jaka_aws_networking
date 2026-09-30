resource "aws_iam_role" "app" {
  for_each = local.app_services
  name     = "${local.name_prefix}-${each.key}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
}


resource "aws_iam_policy" "app_access" {
  for_each    = local.app_services
  name        = "${local.name_prefix}-${each.key}-app-access"
  description = "Parameters, secrets and S3 prefix that ${each.key}-service (and only it) may read"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "ReadOwnParameters"
        Effect = "Allow"
        Action = "ssm:GetParameter"
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/${each.key}-*",
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/redis-*"
        ]
      },
      {
        Sid      = "ReadOwnSecrets"
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = local.app_secret_arns[each.key]
      },
      {
        Sid      = "DecryptSecrets"
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = aws_kms_key.secrets.arn
      },
      {
        Sid      = "ReadWriteOwnObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.microservices.arn}/${each.key}s/*"
      },
      {
        Sid       = "ListOwnPrefix"
        Effect    = "Allow"
        Action    = "s3:ListBucket"
        Resource  = aws_s3_bucket.microservices.arn
        Condition = { StringLike = { "s3:prefix" = ["${each.key}s/*"] } }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_access" {
  for_each   = local.app_services
  role       = aws_iam_role.app[each.key].name
  policy_arn = aws_iam_policy.app_access[each.key].arn
}

resource "aws_iam_role_policy_attachment" "app_managed" {
  for_each   = local.app_managed_policy_attachments
  role       = aws_iam_role.app[each.value.service].name
  policy_arn = each.value.policy_arn
}

resource "aws_iam_instance_profile" "app" {
  for_each = local.app_services
  name     = "${local.name_prefix}-${each.key}-ec2-profile"
  role     = aws_iam_role.app[each.key].name
}
