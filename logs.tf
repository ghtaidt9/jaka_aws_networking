resource "aws_cloudwatch_log_group" "order_service" {
  name              = "/microservice/order-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "payment_service" {
  name              = "/microservice/payment-service"
  retention_in_days = 7
}

# ---- Step 7: RDS log groups ----

# Import: xoá 2 khối này sau khi apply thành công
import {
  to = aws_cloudwatch_log_group.order_db_postgresql
  id = "/aws/rds/instance/${local.name_prefix}-order-db/postgresql"
}

import {
  to = aws_cloudwatch_log_group.payment_db_postgresql
  id = "/aws/rds/instance/${local.name_prefix}-payment-db/postgresql"
}

resource "aws_cloudwatch_log_group" "order_db_postgresql" {
  name              = "/aws/rds/instance/${local.name_prefix}-order-db/postgresql"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "payment_db_postgresql" {
  name              = "/aws/rds/instance/${local.name_prefix}-payment-db/postgresql"
  retention_in_days = var.log_retention_days
}
