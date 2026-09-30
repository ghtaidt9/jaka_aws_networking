resource "aws_ssm_parameter" "order_image_tag" {
  name  = local.order_image_tag_param
  type  = "String"
  value = var.image_tag

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "payment_image_tag" {
  name  = local.payment_image_tag_param
  type  = "String"
  value = var.image_tag

  lifecycle {
    ignore_changes = [value]
  }
}

# Tag that was live before the last deploy - scripts/rollback.sh reads it
resource "aws_ssm_parameter" "order_image_tag_previous" {
  name  = "${local.order_image_tag_param}-previous"
  type  = "String"
  value = var.image_tag

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "payment_image_tag_previous" {
  name  = "${local.payment_image_tag_param}-previous"
  type  = "String"
  value = var.image_tag

  lifecycle {
    ignore_changes = [value]
  }
}
