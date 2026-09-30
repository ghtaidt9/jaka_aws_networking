###############################################
# KMS key for every application secret
###############################################
resource "aws_kms_key" "secrets" {
  description             = "${local.name_prefix} key for Secrets Manager secrets"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.name_prefix}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}


###############################################
# App-user DB credentials (order_user / payment_user)
###############################################

resource "aws_secretsmanager_secret" "order_app_db" {
  name       = local.order_app_db_secret_name
  kms_key_id = aws_kms_key.secrets.arn
  # dev: allow destroy/apply cycles to reuse the name immediately
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "order_app_db" {
  secret_id = aws_secretsmanager_secret.order_app_db.id
  secret_string = jsonencode({
    engine   = "postgres"
    username = local.order_app_db_username
    password = random_password.order_app_user.result
    host     = aws_db_instance.order_db.address
    port     = aws_db_instance.order_db.port
    dbname   = aws_db_instance.order_db.db_name
  })
}

resource "aws_secretsmanager_secret" "payment_app_db" {
  name                    = local.payment_app_db_secret_name
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "payment_app_db" {
  secret_id = aws_secretsmanager_secret.payment_app_db.id
  secret_string = jsonencode({
    engine   = "postgres"
    username = local.payment_app_db_username
    password = random_password.payment_app_user.result
    host     = aws_db_instance.payment_db.address
    port     = aws_db_instance.payment_db.port
    dbname   = aws_db_instance.payment_db.db_name
  })
}

###############################################
# Redis AUTH token (shared cluster, read by both services)
###############################################
resource "aws_secretsmanager_secret" "redis_auth" {
  name                    = local.redis_auth_secret_name
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id     = aws_secretsmanager_secret.redis_auth.id
  secret_string = random_password.redis_auth.result
}

###############################################
# 30-day rotation of the RDS-managed admin secrets (managed rotation, no Lambda)
###############################################

resource "aws_secretsmanager_secret_rotation" "order_db_admin" {
  secret_id          = aws_db_instance.order_db.master_user_secret[0].secret_arn
  rotate_immediately = false
  rotation_rules {
    schedule_expression = "rate(30 days)"
  }
}

resource "aws_secretsmanager_secret_rotation" "payment_db_admin" {
  secret_id          = aws_db_instance.payment_db.master_user_secret[0].secret_arn
  rotate_immediately = false
  rotation_rules {
    schedule_expression = "rate(30 days)"
  }
}
