###############################################
# Security Group for Application Load Balancer
###############################################

resource "aws_security_group" "alb" {
    name        = "${local.name_prefix}-alb-sg"
    description = "Security group for Application Load Balancer"
    vpc_id      = aws_vpc.main.id

    tags = {
        Name = "${local.name_prefix}-alb-sg"
    }
}

###############################################
# Ingress Rules - ALB
###############################################

resource "aws_vpc_security_group_ingress_rule" "alb_ingress_http" {

    security_group_id = aws_security_group.alb.id
    ip_protocol       = "tcp"
    from_port         = 80
    to_port           = 80
    cidr_ipv4         =  "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress_https" {
    
    security_group_id = aws_security_group.alb.id
    ip_protocol       = "tcp"
    from_port         = 443
    to_port           = 443
    cidr_ipv4         = "0.0.0.0/0"
}

###############################################
# Egress Rules - ALB
###############################################

resource "aws_vpc_security_group_egress_rule" "alb_outbound" {

    security_group_id = aws_security_group.alb.id
    ip_protocol       = "-1"
    cidr_ipv4         = "0.0.0.0/0"
}

###############################################
# Security Group for EC2 Instances
###############################################

resource "aws_security_group" "ec2" {
    name = "${local.name_prefix}-ec2-sg"
    description = "Security group for EC2 instances"
    vpc_id = aws_vpc.main.id
    
    tags = {
        Name = "${local.name_prefix}-ec2-sg"
    }
}

###############################################
# Ingress Rules - SSH
###############################################

resource "aws_vpc_security_group_ingress_rule" "ec2_ssh" {
    
    security_group_id = aws_security_group.ec2.id
    ip_protocol       = "tcp"
    from_port         = 22
    to_port           = 22
    cidr_ipv4         = var.ssh_allowed_cidr
}

###############################################
# Ingress Rules - HTTP from ALB only
###############################################

resource "aws_vpc_security_group_ingress_rule" "ec2_ingress_http" {
    
    security_group_id = aws_security_group.ec2.id
    ip_protocol       = "tcp"
    from_port         = 80
    to_port           = 80
    
    referenced_security_group_id = aws_security_group.alb.id
}

###############################################
# Egress Rules - EC2
###############################################

resource "aws_vpc_security_group_egress_rule" "ec2_outbound" {
    
    security_group_id = aws_security_group.ec2.id
    ip_protocol       = "-1"
    cidr_ipv4         = "0.0.0.0/0"
}