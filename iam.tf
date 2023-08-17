data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = var.lambda_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = merge(var.role_tags, var.tags)
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.this.arn,
      "${aws_cloudwatch_log_group.this.arn}:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = [
      data.aws_ssm_parameter.current_eks_version.arn,
      data.aws_ssm_parameter.eks_versions.arn,
      "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}::parameter/aws/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:PutParameter",
    ]
    resources = [
      data.aws_ssm_parameter.current_eks_version.arn,
      data.aws_ssm_parameter.eks_versions.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeAddonVersions",
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.publish_sns ? ["1"] : []

    content {
      effect    = "Allow"
      actions   = ["sns:Publish"]
      resources = [var.sns_topic_arn != null ? var.sns_topic_arn : aws_sns_topic.this[0].arn]
    }
  }

  dynamic "statement" {
    for_each = var.send_email ? ["1"] : []

    content {
      effect = "Allow"
      actions = [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ]
      resources = ["*"]
    }
  }
}

resource "aws_iam_policy" "this" {
  name        = "${var.lambda_name}-execution"
  description = "Allow basic logging, SES and SNS for ${var.lambda_name}"
  policy      = data.aws_iam_policy_document.lambda_policy.json
  tags        = merge(var.role_policy_tags, var.tags)

}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}