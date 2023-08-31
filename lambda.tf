data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/function.py"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "this" {
  filename         = "lambda_function.zip"
  function_name    = var.lambda_name
  role             = aws_iam_role.this.arn
  handler          = "function.handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.8"
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout
  tags             = merge(var.tags, var.lambda_tags)

  environment {
    variables = {
      LOG_LEVEL                     = var.log_level
      PUBLISH_SNS                   = var.publish_sns ? "true" : ""
      SEND_EMAIL                    = var.send_email ? "true" : ""
      ARCH                          = var.architecture
      NOTIFY_AMI                    = var.notify_ami ? "true" : ""
      NOTIFY_EKS                    = var.notify_eks ? "true" : ""
      GPU                           = var.gpu ? "true" : ""
      CURRENT_EKS_VERSION_PARAMETER = var.current_eks_version_parameter_name
      EKS_VERSIONS_PARAMETER        = var.versions_parameter_name
      FROM_ADDRESS                  = var.from_address
      TO_ADDRESS                    = var.to_address
      SNS_TOPIC                     = var.sns_topic_arn == null && var.sns_topic_name == null ? "" : var.sns_topic_arn != null ? var.sns_topic_arn : aws_sns_topic.this[0].arn
      BOTTLEROCKET                  = var.bottlerocket ? "true" : ""
      ADDITIONAL_MESSAGE_INFO       = var.additional_notification_text
    }
  }

  lifecycle {
    precondition {
      condition     = !(var.sns_topic_arn == null && var.sns_topic_name == null && var.publish_sns == true)
      error_message = "Either var.sns_topic_arn or var.sns_topic_name must be set if var.publish_sns is set to `true`."
    }

    precondition {
      condition     = !(var.gpu && var.bottlerocket == false && var.architecture != "x86_64")
      error_message = "When using Amazon Linux 2 GPU instances must be x86_64 architecture."
    }

    precondition {
      condition     = !((var.from_address == "" || var.to_address == "") && var.send_email)
      error_message = "var.from_address and var.to_address have to be set if var.send_email is set to `true`"
    }
  }
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowEventBridgeSchedule"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this.arn
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = var.lambda_log_retention_days
}