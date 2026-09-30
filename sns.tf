resource "aws_sns_topic" "alarms" {
  name = "${local.name_prefix}-alarms"
}

resource "aws_sns_topic_subscription" "alarms_email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

data "aws_iam_policy_document" "alarms_topic" {
  statement {
    sid = "AccountOwner"
    actions = [
      "SNS:Publish", "SNS:Subscribe", "SNS:Receive", "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes", "SNS:ListSubscriptionsByTopic",
      "SNS:AddPermission", "SNS:RemovePermission", "SNS:DeleteTopic"
    ]
    resources = [aws_sns_topic.alarms.arn]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
  statement {
    sid = "AllowCloudWatchAlarms"
    actions = [
      "SNS:Publish"
    ]
    resources = [aws_sns_topic.alarms.arn]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
  statement {
    sid = "AllowRdsEvents"
    actions = [
      "SNS:Publish"
    ]
    resources = [aws_sns_topic.alarms.arn]
    principals {
      type        = "Service"
      identifiers = ["events.rds.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:rds:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

resource "aws_sns_topic_policy" "alarms" {
  arn    = aws_sns_topic.alarms.arn
  policy = data.aws_iam_policy_document.alarms_topic.json
}
