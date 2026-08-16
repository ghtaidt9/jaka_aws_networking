resource "aws_lb_target_group" "ec2_tg" {
  name     = "${local.name_prefix}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    enabled  = true
    path     = "/"
    protocol = "HTTP"
    port     = "traffic-port"
  }
  tags = {
    Name = "${local.name_prefix}-tg"
  }
}

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.ec2_tg.arn
  target_id        = aws_instance.app.id
  port             = 8080
}
