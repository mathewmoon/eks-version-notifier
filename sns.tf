resource "aws_sns_topic" "this" {
  count = var.sns_topic_name != null ? 1 : 0

  name              = var.sns_topic_name
  delivery_policy   = var.sns_delivery_policy
  kms_master_key_id = var.sns_kms_key_id
  fifo_topic        = var.fifo_topic

  lifecycle {
    precondition {
      condition     = var.sns_topic_arn == null
      error_message = "var.create_sns_topic and var.sns_topic_arn are mutually exclusive"
    }

    precondition {
      condition     = var.sns_topic_arn != null ? isnull(var.sns_delivery_policy) : true
      error_message = "Cannot set a delivery policy on an existing SNS topic"
    }
  }
}

resource "aws_sns_topic_policy" "this" {
  count = (var.sns_topic_name != null && var.sns_topic_policy != null) ? 1 : 0

  arn    = aws_sns_topic.this[0].arn
  policy = var.sns_topic_policy

  lifecycle {
    precondition {
      condition     = var.sns_topic_arn == null
      error_message = "Cannot attach a topic policy to an existing topic"
    }
  }
}