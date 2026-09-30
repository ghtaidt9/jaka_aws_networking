locals {
  app_log_groups = {
    "order-service"   = aws_cloudwatch_log_group.order_service.name
    "payment-service" = aws_cloudwatch_log_group.payment_service.name
  }
}

resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  for_each = local.app_log_groups

  name           = "${local.name_prefix}-${each.key}-errors"
  log_group_name = each.value
  pattern        = "\"ERROR\""

  metric_transformation {
    name          = "${each.key}-errors-count"
    namespace     = "Microservices/Logs"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "app_log_errors_high" {
  for_each = aws_cloudwatch_log_metric_filter.app_errors

  alarm_name          = "${local.name_prefix}-${each.key}-log-errors-high"
  alarm_description   = "${each.key} logged more than ${var.alarm_log_errors_threshold} ERROR lines in 5 minutes"
  namespace           = "Microservices/Logs"
  metric_name         = each.value.metric_transformation[0].name
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.alarm_log_errors_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}
