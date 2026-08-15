#######################################################################

resource "aws_security_group" "alb_sg" {
  name        = "${local.name_prefix}-alb-sg"
  description = "SG for ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress_http_rule" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress_https_rule" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_rule" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

#########################################################################

resource "aws_security_group" "ec2_sg" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "SG for EC2"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-ec2-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_ingress_rule" {
  security_group_id            = aws_security_group.ec2_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8081
  referenced_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "ec2_ssh_rule" {
  security_group_id = aws_security_group.ec2_sg.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.ssh_allowed_cidr
}

resource "aws_vpc_security_group_egress_rule" "ec2_egress_rule" {
  security_group_id = aws_security_group.ec2_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

##########################################################################

resource "aws_security_group" "rds_sg" {
  name        = "${local.name_prefix}-rds-sg"
  description = "SG for RDS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-rds-sg"
  }
}


resource "aws_vpc_security_group_ingress_rule" "rds_ingress_rule" {
  security_group_id            = aws_security_group.rds_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.ec2_sg.id
}

######################################################################33333

resource "aws_security_group" "redis_sg" {
  name        = "${local.name_prefix}-redis-sg"
  description = "SG for Redis"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "${local.name_prefix}-redis-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "redis_ingress_rule" {
  security_group_id            = aws_security_group.redis_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  referenced_security_group_id = aws_security_group.ec2_sg.id
}
