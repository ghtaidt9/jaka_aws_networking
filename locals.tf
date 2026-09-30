locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  ecr_registry       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  order_image_repo   = "${local.ecr_registry}/${var.order_ecr_repo_name}"
  payment_image_repo = "${local.ecr_registry}/${var.payment_ecr_repo_name}"

  order_image_tag_param   = "/${var.environment}/order-image-tag"
  payment_image_tag_param = "/${var.environment}/payment-image-tag"

  order_db_url_param   = "/${var.environment}/order-db-url"
  payment_db_url_param = "/${var.environment}/payment-db-url"

  order_db_username   = "order_admin"
  payment_db_username = "payment_admin"

  order_app_db_username      = "order_user"
  payment_app_db_username    = "payment_user"
  order_app_db_secret_name   = "${var.environment}/order-db/app-credentials"
  payment_app_db_secret_name = "${var.environment}/payment-db/app-credentials"

  redis_primary_endpoint_param = "/${var.environment}/redis-primary-endpoint"
  redis_reader_endpoint_param  = "/${var.environment}/redis-reader-endpoint"
  redis_port_param             = "/${var.environment}/redis-port"
  redis_auth_secret_name       = "${var.environment}/redis/auth-token"

  # ElastiCache names member clusters from the replication group ID with a zero-padded suffix.
  redis_cluster_ids = {
    for index in range(var.redis_num_cache_clusters) :
    tostring(index) => "${local.name_prefix}-redis-${format("%03d", index + 1)}"
  }

  s3_bucket_name = "${local.name_prefix}-microservices-${data.aws_caller_identity.current.account_id}"

  alarm_actions = [aws_sns_topic.alarms.arn]

  app_metrics_namespace = "Microservices/App"

  app_services = toset(["order", "payment"])

  #secrets each service's role may read - nothing belonging to the other service/
  app_secret_arns = {
    order = [
      aws_secretsmanager_secret.order_app_db.arn,
      aws_db_instance.order_db.master_user_secret[0].secret_arn,
      aws_secretsmanager_secret.redis_auth.arn,
    ]
    payment = [
      aws_secretsmanager_secret.payment_app_db.arn,
      aws_db_instance.payment_db.master_user_secret[0].secret_arn,
      aws_secretsmanager_secret.redis_auth.arn,
    ]
  }

  app_managed_policy_arns = {
    ssm_core         = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ecr_readonly     = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    cloudwatch_agent = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  app_managed_policy_attachments = {
    for pair in setproduct(local.app_services, keys(local.app_managed_policy_arns)) :
    "${pair[0]}-${pair[1]}" => { service = pair[0], policy_arn = local.app_managed_policy_arns[pair[1]] }
  }
}
