###############################################
# Application Load Balancer
###############################################

resource "aws_lb" "app_alb" {
    name                = "${local.name_prefix}-alb"
    internal            = false
    load_balancer_type  = "application"

    security_groups     = [aws_security_group.alb.id]
    subnets             = [aws_subnet.public_1.id, aws_subnet.public_2.id]

    tags = {
        Name = "${local.name_prefix}-alb"
    }
}