resource "aws_autoscaling_policy" "order_cpu_target" {
  name                      = "${local.name_prefix}-order-cpu-target"
  autoscaling_group_name    = aws_autoscaling_group.order_asg.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 180
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.asg_target_cpu
  }
}

resource "aws_autoscaling_policy" "payment_cpu_target" {
  name                      = "${local.name_prefix}-payment-cpu-target"
  autoscaling_group_name    = aws_autoscaling_group.payment_asg.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 180

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.asg_target_cpu
  }
}
