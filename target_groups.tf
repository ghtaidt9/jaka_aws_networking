resource "aws_lb_target_group" "payment_tg" {
  name     = "${local.name_prefix}-payment-tg"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    enabled  = true
    path     = "/api/payments/actuator/health"
    protocol = "HTTP"
    port     = "traffic-port"

    # ~20s from app-up to receiving traffic (default 30s x 3 = 90s)
    interval          = 10
    healthy_threshold = 2
  }
  tags = {
    Name = "${local.name_prefix}-payment-tg"
  }
}


resource "aws_lb_target_group" "order_tg" {
  name     = "${local.name_prefix}-order-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    enabled  = true
    path     = "/api/orders/actuator/health"
    protocol = "HTTP"
    port     = "traffic-port"

    # ~20s from app-up to receiving traffic (default 30s x 3 = 90s)
    interval          = 10
    healthy_threshold = 2
  }
  tags = {
    Name = "${local.name_prefix}-order-tg"
  }
}
