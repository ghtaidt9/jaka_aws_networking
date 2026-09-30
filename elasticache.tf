resource "random_password" "redis_auth" {
  length  = 32
  special = false
}

resource "aws_elasticache_subnet_group" "redis_subnet" {
  name       = "${local.name_prefix}-redis-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${local.name_prefix}-redis"
  description          = "Shared Redis cache for order-service and payment-service"

  engine         = "redis"
  engine_version = var.redis_engine_version
  node_type      = var.redis_node_type
  port           = var.redis_port

  num_cache_clusters         = var.redis_num_cache_clusters
  automatic_failover_enabled = true
  multi_az_enabled           = true

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth.result

  subnet_group_name  = aws_elasticache_subnet_group.redis_subnet.name
  security_group_ids = [aws_security_group.redis_sg.id]

  apply_immediately = true

  tags = {
    Name = "${local.name_prefix}-redis"
  }
}

resource "aws_ssm_parameter" "redis_primary_endpoint" {
  name  = local.redis_primary_endpoint_param
  type  = "String"
  value = aws_elasticache_replication_group.main.primary_endpoint_address
}

resource "aws_ssm_parameter" "redis_reader_endpoint" {
  name  = local.redis_reader_endpoint_param
  type  = "String"
  value = aws_elasticache_replication_group.main.reader_endpoint_address
}

resource "aws_ssm_parameter" "redis_port" {
  name  = local.redis_port_param
  type  = "String"
  value = tostring(aws_elasticache_replication_group.main.port)
}
