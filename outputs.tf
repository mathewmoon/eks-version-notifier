output "sns_topic" {
  description = "The SNS topic that new versions are sent to"
  value       = var.sns_topic_arn != null ? var.sns_topic_arn : try(aws_sns_topic.this[0].arn, "")
}

output "function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "lambda_role_arn" {
  description = "The ARN of the role attached to the Lambda function"
  value       = aws_iam_role.this.arn
}

output "lambda_iam_policy" {
  description = "The actial IAM policy json for the Lambda function"
  value       = data.aws_iam_policy_document.lambda_policy.json
}

output "schedule_expression" {
  description = "The Cloudwatch schedule expression applied to the EventBridge rule to run the Lambda"
  value       = var.schedule_expression
}

output "eventbridge_rule_arn" {
  description = "The ARN of the EventBridge Rule that triggers Lambda"
  value       = aws_cloudwatch_event_rule.this.arn
}

output "sns_topic_policy" {
  description = "The resource policy applied to the SNS topic"
  value       = try(jsondecode(aws_sns_topic.this[0].policy), "")
}