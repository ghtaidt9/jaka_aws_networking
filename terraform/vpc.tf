###############################################
# VPC
###############################################
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_support  = true
    enable_dns_hostnames = true

    tags = {
        Name  = "${local.name_prefix}-vpc"
    }
}

###############################################
# Public Subnet AZ1
###############################################

resource "aws_subnet" "public_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_1_cidr
    availability_zone = var.az1
    map_public_ip_on_launch = true

    tags = {
        Name = "${local.name_prefix}-public-1"
        Tier = "public"
    }
}

###############################################
# Public Subnet AZ2
###############################################
resource "aws_subnet" "public_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_2_cidr
    availability_zone = var.az2
    map_public_ip_on_launch = true

    tags = {
        Name = "${local.name_prefix}-public-2"
        Tier = "public"
    }
}


###############################################
# Private Subnet AZ1
###############################################

resource "aws_subnet" "private_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_1_cidr
    availability_zone = var.az1

    tags = {
        Name = "${local.name_prefix}-private-1"
        Tier = "private"
    }
}

###############################################
# Private Subnet AZ2
###############################################
resource "aws_subnet" "private_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_2_cidr
    availability_zone = var.az2

    tags = {
        Name = "${local.name_prefix}-private-2"
        Tier = "private"
    }
}