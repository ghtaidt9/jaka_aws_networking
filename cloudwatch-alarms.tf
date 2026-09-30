resource "aws_cloudwatch_metric_alarm" "order_asg_cpu_high" {
  alarm_name          = "${local.name_prefix}-order-asg-cpu-high"
  alarm_description   = "order-service ASG average CPU above ${var.alarm_cpu_high_threshold}% for 5 minutes"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.alarm_cpu_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.order_asg.name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}


resource "aws_cloudwatch_metric_alarm" "payment_asg_cpu_high" {
  alarm_name          = "${local.name_prefix}-payment-asg-cpu-high"
  alarm_description   = "payment-service ASG average CPU above ${var.alarm_cpu_high_threshold}% for 5 minutes"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.alarm_cpu_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.payment_asg.name
  }
  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}


resource "aws_cloudwatch_metric_alarm" "order_asg_memory_high" {
  alarm_name          = "${local.name_prefix}-order-asg-memory-high"
  alarm_description   = "order-service ASG average memory above ${var.alarm_memory_high_threshold}"
  namespace           = "CWAgent"
  metric_name         = "mem_used_percent"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.alarm_memory_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.order_asg.name
  }
  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "payment_asg_memory_high" {
  alarm_name          = "${local.name_prefix}-payment-asg-memory-high"
  alarm_description   = "payment-service ASG average memory above ${var.alarm_memory_high_threshold}"
  namespace           = "CWAgent"
  metric_name         = "mem_used_percent"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.alarm_memory_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.payment_asg.name
  }
  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "order_db_cpu_high" {
  alarm_name          = "${local.name_prefix}-order-db-cpu-high"
  alarm_description   = "order-db CPU above ${var.alarm_rds_cpu_threshold}%"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.alarm_rds_cpu_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.order_db.identifier
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "order_db_connections_high" {
  alarm_name          = "${local.name_prefix}-order-db-connections-high"
  alarm_description   = "order-db DatabaseConnections above ${var.alarm_rds_connections_threshold}"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.alarm_rds_connections_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.order_db.identifier
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "order_db_free_storage_low" {
  alarm_name          = "${local.name_prefix}-order-db-free-storage-low"
  alarm_description   = "order-db FreeStorageSpace below ${var.alarm_rds_free_storage_bytes} bytes"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.alarm_rds_free_storage_bytes
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.order_db.identifier
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "payment_db_cpu_high" {
  alarm_name          = "${local.name_prefix}-payment-db-cpu-high"
  alarm_description   = "payment-db CPU above ${var.alarm_rds_cpu_threshold}%"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.alarm_rds_cpu_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.payment_db.identifier
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "payment_db_connections_high" {
  alarm_name          = "${local.name_prefix}-payment-db-connections-high"
  alarm_description   = "payment-db DatabaseConnections above ${var.alarm_rds_connections_threshold}"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.alarm_rds_connections_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.payment_db.identifier
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "payment_db_free_storage_low" {
  alarm_name          = "${local.name_prefix}-payment-db-free-storage-low"
  alarm_description   = "payment-db FreeStorageSpace below ${var.alarm_rds_free_storage_bytes} bytes"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.alarm_rds_free_storage_bytes
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.payment_db.identifier
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "order_tg_unhealthy_hosts" {
  alarm_name        = "${local.name_prefix}-order-tg-unhealthy"
  alarm_description = "order-service target group has unhealthy targets"

  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = aws_lb_target_group.order_tg.arn_suffix
    LoadBalancer = aws_lb.app_alb.arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "payment_tg_unhealthy_hosts" {
  alarm_name        = "${local.name_prefix}-payment-tg-unhealthy"
  alarm_description = "payment-service target group has unhealthy targets"

  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = aws_lb_target_group.payment_tg.arn_suffix
    LoadBalancer = aws_lb.app_alb.arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_high" {
  alarm_name          = "${local.name_prefix}-alb-5xx-high"
  alarm_description   = "ALB returned more than ${var.alarm_alb_5xx_threshold} 5xx responses in 5 minutes"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.alarm_alb_5xx_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.app_alb.arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "alb_latency_high" {
  alarm_name          = "${local.name_prefix}-alb-latency-high"
  alarm_description   = "ALB p95 target response time above ${var.alarm_alb_latency_seconds}"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  extended_statistic  = "p95"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.alarm_alb_latency_seconds
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.app_alb.arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "redis_cpu_high" {
  for_each = local.redis_cluster_ids

  alarm_name        = "${local.name_prefix}-redis-${each.key}-cpu-high"
  alarm_description = "Redis node ${each.value} CPU above ${var.alarm_redis_cpu_threshold}%"

  namespace   = "AWS/ElastiCache"
  metric_name = "CPUUtilization"
  statistic   = "Average"

  period              = 300
  evaluation_periods  = 2
  threshold           = var.alarm_redis_cpu_threshold
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    CacheClusterId = each.value
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "redis_memory_high" {
  for_each = local.redis_cluster_ids

  alarm_name        = "${local.name_prefix}-redis-${each.key}-memory-high"
  alarm_description = "Redis node ${each.value} memory usage above ${var.alarm_redis_memory_threshold}%"

  namespace   = "AWS/ElastiCache"
  metric_name = "DatabaseMemoryUsagePercentage"
  statistic   = "Average"

  period              = 300
  evaluation_periods  = 2
  threshold           = var.alarm_redis_memory_threshold
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    CacheClusterId = each.value
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "order_asg_disk_high" {
  alarm_name          = "${local.name_prefix}-order-asg-disk-high"
  alarm_description   = "Order service root disk usage above ${var.alarm_disk_high_threshold}%"
  namespace           = "CWAgent"
  metric_name         = "disk_used_percent"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.alarm_disk_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.order_asg.name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "payment_asg_disk_high" {
  alarm_name          = "${local.name_prefix}-payment-asg-disk-high"
  alarm_description   = "Payment service root disk usage above ${var.alarm_disk_high_threshold}%"
  namespace           = "CWAgent"
  metric_name         = "disk_used_percent"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.alarm_disk_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.payment_asg.name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "order_hikari_pool_high" {
  alarm_name          = "${local.name_prefix}-order-hikari-pool-high"
  alarm_description   = "Order service HikariCP pool usage above ${var.alarm_hikari_pool_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.alarm_hikari_pool_threshold
  evaluation_periods  = 3
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "usage"
    expression  = "100 * active / max"
    label       = "Hikari pool usage %"
    return_data = true
  }

  metric_query {
    id = "active"
    metric {
      namespace   = local.app_metrics_namespace
      metric_name = "hikaricp.connections.active.value"
      period      = 60
      stat        = "Maximum"
      dimensions = {
        service     = "order-service"
        environment = var.environment
        pool        = "HikariPool-1"
      }
    }
  }

  metric_query {
    id = "max"
    metric {
      namespace   = local.app_metrics_namespace
      metric_name = "hikaricp.connections.max.value"
      period      = 60
      stat        = "Maximum"
      dimensions = {
        service     = "order-service"
        environment = var.environment
        pool        = "HikariPool-1"
      }
    }
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

}

resource "aws_cloudwatch_metric_alarm" "payment_hikari_pool_high" {
  alarm_name          = "${local.name_prefix}-payment-hikari-pool-high"
  alarm_description   = "payment-service Hikari pool usage above ${var.alarm_hikari_pool_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.alarm_hikari_pool_threshold
  evaluation_periods  = 3
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "usage"
    expression  = "100 * active / max"
    label       = "Hikari pool usage %"
    return_data = true
  }

  metric_query {
    id = "active"
    metric {
      namespace   = local.app_metrics_namespace
      metric_name = "hikaricp.connections.active.value"
      period      = 60
      stat        = "Maximum"
      dimensions = {
        service     = "payment-service"
        environment = var.environment
        pool        = "HikariPool-1"
      }
    }
  }

  metric_query {
    id = "max"
    metric {
      namespace   = local.app_metrics_namespace
      metric_name = "hikaricp.connections.max.value"
      period      = 60
      stat        = "Maximum"
      dimensions = {
        service     = "payment-service"
        environment = var.environment
        pool        = "HikariPool-1"
      }
    }
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}
