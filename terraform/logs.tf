resource "aws_cloudwatch_log_group" "order_service" {
  name              = "/microservice/order-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "payment_service" {
  name              = "/microservice/payment-service"
  retention_in_days = 7
}
