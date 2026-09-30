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

########################
# ECR / container images
########################

variable "order_ecr_repo_name" {
  description = "ECR repository name for the order-service image"
  type        = string
  default     = "order-service"
}

variable "payment_ecr_repo_name" {
  description = "ECR repository name for the payment-service image"
  type        = string
  default     = "payment-service"
}

variable "image_tag" {
  description = "Initial image tag written to the per-service image-tag SSM parameters; after creation, scripts/deploy.sh owns the value"
  type        = string
  default     = "latest"
}

########################
# Auto Scaling
########################

variable "asg_min_size" {
  description = "Minimum size for the order/payment Auto Scaling Groups"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum size for the order/payment Auto Scaling Groups"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Desired capacity for the order/payment Auto Scaling Groups"
  type        = number
  default     = 2
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "rds_allocated_storage" {
  type    = number
  default = 20
}

variable "postgres_engine_version" {
  type    = string
  default = "16"
}

variable "rds_retention_period" {
  description = "Number of days to retain automated RDS backups"
  type        = number
  default     = 1
}

variable "rds_skip_final_snapshot" {
  description = "Whehter to skip taking a final DB snapshot when the instance is deleted/replaced. Keep true for dev/lab/staging; set false for production env to avoid data loss"
  type        = bool
  default     = true
}

variable "redis_engine_version" {
  description = "ElastiCache Redis engine version"
  type        = string
  default     = "7.1" # matches redis:7-alpine used in both services' docker-compose.yml
}

variable "redis_node_type" {
  description = "ElastiCache node instance type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_port" {
  description = "ElastiCache Redis port"
  type        = number
  default     = 6379
}

variable "redis_num_cache_clusters" {
  description = "Number of Redis cache clusters in the replication group"
  type        = number
  default     = 2

  validation {
    condition     = var.redis_num_cache_clusters >= 2
    error_message = "redis_num_cache_clusters must be at least 2 when automatic failover is enabled."
  }
}

variable "s3_ia_transition_days" {
  description = "Days ater object creattion before transitioning to STANDARD_IA"
  type        = number
  default     = 30
}

variable "s3_glacier_transition_days" {
  description = "Days after object creation transitioning to GLACIER"
  type        = number
  default     = 90
}

variable "s3_noncurrent_version_expiration_days" {
  description = "Days to keep noncurrent (old) object versions before permanent deletion"
  type        = number
  default     = 90
}

variable "alarm_email" {
  description = "Email endpoint for SNS alarm"
  type        = string
}

variable "alarm_cpu_high_threshold" {
  description = "EC2/ASG average CPU percent that triggers the high-CPU alarm"
  type        = number
  default     = 70
}

variable "alarm_memory_high_threshold" {
  description = "EC2/ASG average memory percent (CWAgent) that triggers the high-memory alarm"
  type        = number
  default     = 80
}

variable "alarm_rds_cpu_threshold" {
  description = "RDS CPU percent that triggers the high-CPU alarm"
  type        = number
  default     = 75
}

variable "alarm_rds_connections_threshold" {
  description = "RDS DatabaseConnections count that triggers the connection-pressure alarm"
  type        = number
  default     = 80
}

variable "alarm_rds_free_storage_bytes" {
  description = "RDS FreeStorageSpace in bytes below which the low-storage alarm fires"
  type        = number
  default     = 2147483648 # 2 GiB
}

variable "alarm_alb_5xx_threshold" {
  description = "Count of ALB-generated 5xx responses per 5 minutes that triggers the alarm"
  type        = number
  default     = 5
}

variable "alarm_alb_latency_seconds" {
  description = "ALB p95 target response time in seconds that triggers the latency alarm"
  type        = number
  default     = 2
}

variable "alarm_redis_cpu_threshold" {
  description = "ElastiCache CPU percent that triggers the alarm"
  type        = number
  default     = 75
}

variable "alarm_redis_memory_threshold" {
  description = "ElastiCache DatabaseMemoryUsagePercentage that triggers the alarm"
  type        = number
  default     = 75
}

variable "asg_target_cpu" {
  description = "Target average CPU percent for the ASG target-tracking scaling policy"
  type        = number
  default     = 60
}

variable "alarm_disk_high_threshold" {
  description = "EC2/ASG average disk usage percent (CWAgent) that triggers the high-disk alarm"
  type        = number
  default     = 80

  validation {
    condition     = var.alarm_disk_high_threshold >= 50 && var.alarm_disk_high_threshold <= 90
    error_message = "alarm_disk_high_threshold must be between 50 and 90."
  }
}

variable "alarm_log_errors_threshold" {
  description = "Number of ERROR log lines per 5 minutes (per service) that triggers the alarm"
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "Retention for RDS-exported PostgreSQL logs in CloudWatch Logs"
  type        = number
  default     = 7
}

variable "alarm_hikari_pool_threshold" {
  description = "Hikari pool threshold"
  type        = number
  default     = 90
}
