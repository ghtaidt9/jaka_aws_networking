###############################################
# Application Load Balancer
###############################################

resource "aws_lb" "app_alb" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]
  subnets         = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.order_tg.arn
  }
}

resource "aws_lb_listener_rule" "orders" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["/api/orders", "/api/orders/*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.order_tg.arn
  }
}

resource "aws_lb_listener_rule" "payments" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200
  condition {
    path_pattern {
      values = ["/api/payments", "/api/payments/*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payment_tg.arn
  }
}
