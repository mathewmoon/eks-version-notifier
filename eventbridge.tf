resource "aws_cloudwatch_event_rule" "this" {
  name                = var.lambda_name
  description         = "Trigger ${var.lambda_name} on a schedule"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "this" {
  arn  = aws_lambda_function.this.arn
  rule = aws_cloudwatch_event_rule.this.id
}