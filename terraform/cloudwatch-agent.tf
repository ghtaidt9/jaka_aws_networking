###############################################
# CloudWatch Agent config (SSM Parameter Store)
###############################################

resource "aws_ssm_parameter" "order_service_agent_config" {
  name = "AmazonCloudWatch-${local.name_prefix}-order-service-agent-config"
  type = "String"
  value = templatefile("${path.module}/templates/cloudwatch-agent-config.json.tpl", {
    log_group_name  = aws_cloudwatch_log_group.order_service.name
    log_stream_name = "order-service/{instance_id}"
  })

  tags = {
    Name = "${local.name_prefix}-order-service-agent-config"
  }
}


resource "aws_ssm_parameter" "payment_service_agent_config" {
  name = "AmazonCloudWatch-${local.name_prefix}-payment-service-agent-config"
  type = "String"
  value = templatefile("${path.module}/templates/cloudwatch-agent-config.json.tpl", {
    log_group_name  = aws_cloudwatch_log_group.payment_service.name
    log_stream_name = "payment-service/{instance_id}"
  })

  tags = {
    Name = "${local.name_prefix}-payment-service-agent-config"
  }
}
