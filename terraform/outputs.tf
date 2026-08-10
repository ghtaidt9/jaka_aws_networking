###############################################
# VPC
###############################################

output "vpc_id" {
    description = "The ID of the VPC"
    value       = aws_vpc.main.id
}

###############################################
# ALB
###############################################

output "alb_dns_name" {
    description = "The DNS name of the ALB"
    value       = aws_lb.app_alb.dns_name
}

###############################################
# EC2
###############################################

output "ec2_private_ip" {
    description = "The private IP address of the EC2 instance"
    value       = aws_instance.app.private_ip
}