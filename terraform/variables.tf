########################
# General
########################

variable "project" {
  description = "Project name"
  type        = string
  default     = "vpc-lab"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

########################
# Networking
########################

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  type    = string
  default = "10.0.11.0/24"
}

variable "private_subnet_2_cidr" {
  type    = string
  default = "10.0.12.0/24"
}

########################
# Availability Zones
########################

variable "az1" {
  type    = string
  default = "us-east-1a"
}

variable "az2" {
  type    = string
  default = "us-east-1b"
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH into EC2"
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}