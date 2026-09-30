resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "ASG CPU Utilization"
          region = var.region
          period = 300
          stat   = "Average"
          view   = "timeSeries"

          annotations = {
            horizontal = [{
              label = "CPU alarm threshold"
              value = var.alarm_cpu_high_threshold
            }]
          }

          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.order_asg.name, { label = "order-service" }],
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.payment_asg.name, { label = "payment-service" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "CWAgent Memory Utilization"
          region = var.region
          period = 300
          stat   = "Average"
          view   = "timeSeries"

          annotations = {
            horizontal = [{
              label = "Memory alarm threshold"
              value = var.alarm_memory_high_threshold
            }]
          }

          metrics = [
            ["CWAgent", "mem_used_percent", "AutoScalingGroupName", aws_autoscaling_group.order_asg.name, { label = "order-service" }],
            ["CWAgent", "mem_used_percent", "AutoScalingGroupName", aws_autoscaling_group.payment_asg.name, { label = "payment-service" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "CWAgent Disk Utilization"
          region = var.region
          period = 300
          stat   = "Average"
          view   = "timeSeries"

          annotations = {
            horizontal = [{
              label = "Disk alarm threshold"
              value = var.alarm_disk_high_threshold
            }]
          }

          metrics = [
            ["CWAgent", "disk_used_percent", "AutoScalingGroupName", aws_autoscaling_group.order_asg.name, { label = "order-service" }],
            ["CWAgent", "disk_used_percent", "AutoScalingGroupName", aws_autoscaling_group.payment_asg.name, { label = "payment-service" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "ALB Errors and Latency"
          region = var.region
          period = 300
          view   = "timeSeries"

          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.app_alb.arn_suffix, { stat = "Sum", label = "target 5xx" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.app_alb.arn_suffix, { stat = "p95", label = "target p95 latency" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "RDS CPU and Connections"
          region = var.region
          period = 300
          stat   = "Average"
          view   = "timeSeries"

          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.order_db.identifier, { label = "order CPU" }],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.order_db.identifier, { label = "order connections" }],
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.payment_db.identifier, { label = "payment CPU" }],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.payment_db.identifier, { label = "payment connections" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "Redis CPU and Memory"
          region = var.region
          period = 300
          stat   = "Average"
          view   = "timeSeries"

          metrics = concat(
            [
              for cluster_id in values(local.redis_cluster_ids) : [
                "AWS/ElastiCache",
                "CPUUtilization",
                "CacheClusterId",
                cluster_id,
                { label = "${cluster_id} CPU" }
              ]
            ],
            [
              for cluster_id in values(local.redis_cluster_ids) : [
                "AWS/ElastiCache",
                "DatabaseMemoryUsagePercentage",
                "CacheClusterId",
                cluster_id,
                { label = "${cluster_id} memory" }
              ]
            ]
          )
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6
        properties = {
          title  = "ALB Traffic"
          region = var.region
          period = 60
          view   = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.app_alb.arn_suffix, { stat = "Sum", label = "requests" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", aws_lb.app_alb.arn_suffix, { stat = "Sum", label = "target 4xx" }],
            ["AWS/ApplicationELB", "ActiveConnectionCount", "LoadBalancer", aws_lb.app_alb.arn_suffix, { stat = "Sum", label = "active connections" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 18
        width  = 12
        height = 6
        properties = {
          title  = "Target Group Health"
          region = var.region
          period = 60
          view   = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.order_tg.arn_suffix, "LoadBalancer", aws_lb.app_alb.arn_suffix, { stat = "Minimum", label = "order healthy" }],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", aws_lb_target_group.order_tg.arn_suffix, "LoadBalancer", aws_lb.app_alb.arn_suffix, { stat = "Maximum", label = "order unhealthy" }],
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.payment_tg.arn_suffix, "LoadBalancer", aws_lb.app_alb.arn_suffix, { stat = "Minimum", label = "payment healthy" }],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", aws_lb_target_group.payment_tg.arn_suffix, "LoadBalancer", aws_lb.app_alb.arn_suffix, { stat = "Maximum", label = "payment unhealthy" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 24
        width  = 12
        height = 6
        properties = {
          title  = "RDS Latency and Free Storage"
          region = var.region
          period = 300
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", aws_db_instance.order_db.identifier, { label = "order read latency (s)" }],
            ["AWS/RDS", "WriteLatency", "DBInstanceIdentifier", aws_db_instance.order_db.identifier, { label = "order write latency (s)" }],
            ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", aws_db_instance.payment_db.identifier, { label = "payment read latency (s)" }],
            ["AWS/RDS", "WriteLatency", "DBInstanceIdentifier", aws_db_instance.payment_db.identifier, { label = "payment write latency (s)" }],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.order_db.identifier, { label = "order free storage", yAxis = "right" }],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.payment_db.identifier, { label = "payment free storage", yAxis = "right" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 24
        width  = 12
        height = 6
        properties = {
          title  = "Redis Cache Hit Rate"
          region = var.region
          period = 300
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            for cluster_id in values(local.redis_cluster_ids) : [
              "AWS/ElastiCache", "CacheHitRate", "CacheClusterId", cluster_id, { label = "${cluster_id} hit rate %" }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 30
        width  = 12
        height = 6
        properties = {
          title  = "EC2 Disk I/O (bytes)"
          region = var.region
          period = 300
          stat   = "Sum"
          view   = "timeSeries"
          metrics = [
            ["CWAgent", "diskio_read_bytes", "AutoScalingGroupName", aws_autoscaling_group.order_asg.name, { label = "order read" }],
            ["CWAgent", "diskio_write_bytes", "AutoScalingGroupName", aws_autoscaling_group.order_asg.name, { label = "order write" }],
            ["CWAgent", "diskio_read_bytes", "AutoScalingGroupName", aws_autoscaling_group.payment_asg.name, { label = "payment read" }],
            ["CWAgent", "diskio_write_bytes", "AutoScalingGroupName", aws_autoscaling_group.payment_asg.name, { label = "payment write" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 30
        width  = 12
        height = 6
        properties = {
          title  = "Application ERROR log lines"
          region = var.region
          period = 300
          stat   = "Sum"
          view   = "timeSeries"
          metrics = [
            ["Microservices/Logs", "order-service-errors-count", { label = "order-service" }],
            ["Microservices/Logs", "payment-service-errors-count", { label = "payment-service" }]
          ]
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 36
        width  = 24
        height = 6
        properties = {
          title  = "Latest ERROR log lines"
          region = var.region
          view   = "table"
          query  = "SOURCE '${aws_cloudwatch_log_group.order_service.name}' | SOURCE '${aws_cloudwatch_log_group.payment_service.name}' | fields @timestamp, @logStream, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 50"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 42
        width  = 24
        height = 6
        properties = {
          title  = "App HTTP latency (avg ms) per service/uri"
          region = var.region
          period = 60
          view   = "timeSeries"
          metrics = [
            [{ expression = "SEARCH('Namespace=\"${local.app_metrics_namespace}\" MetricName=\"http.server.requests.avg\"', 'Average', 60)", id = "e1", label = "" }]
          ]
        }
      }

    ]
  })
}
