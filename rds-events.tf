resource "aws_db_event_subscription" "rds_critical" {
  name             = "${local.name_prefix}-rds-critical"
  sns_topic        = aws_sns_topic.alarms.arn
  source_type      = "db-instance"
  source_ids       = [aws_db_instance.order_db.identifier, aws_db_instance.payment_db.identifier]
  event_categories = ["failover", "failure", "availability", "low storage"]
  depends_on       = [aws_sns_topic_policy.alarms]
}