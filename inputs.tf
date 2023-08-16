variable "send_email" {
  description = "Whether to send email via SES"
  type        = string
  default     = null
}

variable "publish_sns" {
  description = "Whether to publish to SNS topic"
}

variable "versions_parameter_name" {
  description = "Name to use for storing EKS and corresponding AMI versions"
  type        = string
}

variable "create_parameters" {
  description = "If `true` then create the parameters"
}

variable "current_eks_version_parameter_name" {
  description = "Name to use for storing current EKS version"
  type        = string
}

variable "bottlerocket" {
  description = "Whether or not to use Bottlerocket AMI"
  type        = bool
  default     = true
}

variable "architecture" {
  description = "The architecture for the AMI. If var.bottlerocket is `false` then this is mutually exclusive with var.gpu"
  type        = string
  default     = "x86_64"
  validation {
    condition     = contains(["x86_64", "arm64"], var.architecture)
    error_message = "architecture must be one of x86_64 or arm64"
  }
}

variable "gpu" {
  description = "Use GPU AMI. If var.bottlerocket is `false` then this is mutually exclusive with var.architecture"
  type        = bool
  default     = false
}

variable "sns_topic_name" {
  description = "Name for SNS topic to create. Mutually exclusive to var.sns_topic_arn"
  type        = string
  default     = null
}

variable "sns_topic_arn" {
  description = "The ARN of an existing SNS topic to publish to. Mutually exclusive to var.sns_topic_name"
  type        = string
  default     = null
}

variable "from_address" {
  description = "The From address to use with SES"
  type        = string
  default     = ""
}

variable "to_address" {
  description = "The To address to use with SES"
  type        = string
  default     = ""
}

variable "lambda_name" {
  description = "Name for the newly created Lambda"
  type        = string
}

variable "notify_ami" {
  description = "Whether the function should actually send notifications for AMI updates"
  type        = bool
  default     = false
}

variable "notify_eks" {
  description = "Whether the function should actually send notifications for EKS versions"
  type        = bool
  default     = false
}

variable "current_eks_version" {
  description = "The current EKS version to check for new versions above and AMI versions for"
  type        = string
}

variable "lambda_memory_size" {
  description = "The amount of RAM to allocate to the function"
  type        = number
  default     = 1024
}

variable "lambda_timeout" {
  description = "The timeout for the function in seconds"
  type        = number
  default     = 30
}

variable "log_level" {
  description = "Log level for Lambda function"
  type        = string
  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR", "EXCEPTION"], var.log_level)
    error_message = "var.log_level must be one of DEBUG, INFO, WARNING, ERROR, EXCEPTION"
  }
}

variable "sns_topic_policy" {
  description = "A policy to attach to the created SNS topic. Cannot be used when specifying an existing topic using var.sns_topic_arn"
  type        = string
  default     = null
  validation {
    condition     = var.sns_topic_policy == null || can(jsondecode(var.sns_topic_policy))
    error_message = "var.sns_topic_policy: Invalid JSON"
  }
}

variable "schedule_expression" {
  description = "A valid CloudWatch schedule expression that will be used for triggering the Lambda"
  type        = string
  default     = "rate(12 hours)"
  validation {
    condition = length(regexall(
      "^(rate|cron)\\(((((([*])|(((([0-5])?[0-9])((-(([0-5])?[0-9])))?)))((/(([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?[0-9])))?))(,(((([*])|(((([0-5])?[0-9])((-(([0-5])?[0-9])))?)))((/(([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?[0-9])))?)))* (((([*])|(((((([0-1])?[0-9]))|(([2][0-3])))((-(((([0-1])?[0-9]))|(([2][0-3])))))?)))((/(([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?[0-9])))?))(,(((([*])|(((((([0-1])?[0-9]))|(([2][0-3])))((-(((([0-1])?[0-9]))|(([2][0-3])))))?)))((/(([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?[0-9])))?)))* (((((((([*])|(((((([1-2])?[0-9]))|(([3][0-1]))|(([1-9])))((-(((([1-2])?[0-9]))|(([3][0-1]))|(([1-9])))))?)))((/(([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?[0-9])))?))|(L)|(((((([1-2])?[0-9]))|(([3][0-1]))|(([1-9])))W))))(,(((((([*])|(((((([1-2])?[0-9]))|(([3][0-1]))|(([1-9])))((-(((([1-2])?[0-9]))|(([3][0-1]))|(([1-9])))))?)))((/(([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?[0-9])))?))|(L)|(((((([1-2])?[0-9]))|(([3][0-1]))|(([1-9])))W)))))*)|([?])) (((([*])|((((([1-9]))|(([1][0-2])))((-((([1-9]))|(([1][0-2])))))?))|((((JAN)|(FEB)|(MAR)|(APR)|(MAY)|(JUN)|(JUL)|(AUG)|(SEP)|(OKT)|(NOV)|(DEC))((-((JAN)|(FEB)|(MAR)|(APR)|(MAY)|(JUN)|(JUL)|(AUG)|(SEP)|(OKT)|(NOV)|(DEC))))?)))((/(([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?[0-9])))?))(,(((([*])|((((([1-9]))|(([1][0-2])))((-((([1-9]))|(([1][0-2])))))?))|((((JAN)|(FEB)|(MAR)|(APR)|(MAY)|(JUN)|(JUL)|(AUG)|(SEP)|(OKT)|(NOV)|(DEC))((-((JAN)|(FEB)|(MAR)|(APR)|(MAY)|(JUN)|(JUL)|(AUG)|(SEP)|(OKT)|(NOV)|(DEC))))?)))((/(([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?[0-9])))?)))* (((((((([*])|((([0-6])((-([0-6])))?))|((((SUN)|(MON)|(TUE)|(WED)|(THU)|(FRI)|(SAT))((-((SUN)|(MON)|(TUE)|(WED)|(THU)|(FRI)|(SAT))))?)))((/(([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?[0-9])))?))|((([0-6])L))|(W)|(([#][1-5]))))(,(((((([*])|((([0-6])((-([0-6])))?))|((((SUN)|(MON)|(TUE)|(WED)|(THU)|(FRI)|(SAT))((-((SUN)|(MON)|(TUE)|(WED)|(THU)|(FRI)|(SAT))))?)))((/(([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?[0-9])))?))|((([0-6])L))|(W)|(([#][1-5])))))*)|([?]))((( (((([*])|((([1-2][0-9][0-9][0-9])((-([1-2][0-9][0-9][0-9])))?)))((/(([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?[0-9])))?))(,(((([*])|((([1-2][0-9][0-9][0-9])((-([1-2][0-9][0-9][0-9])))?)))((/(([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?([0-9])?[0-9])))?)))*))?))|(\\d\\s(minute|minutes|hour|hours|day|days)\\))$",
      var.schedule_expression
    )) != 0
    error_message = "Invalid schedule expression"
  }
}

variable "lambda_log_retention_days" {
  description = "Retention in days to apply to the Function's Cloudwatch log"
  type        = number
  default     = 14
}

variable "sns_delivery_policy" {
  description = "Deliver policy for created SNS topics"
  type        = string
  default     = null
  validation {
    condition     = var.sns_delivery_policy == null || can(jsondecode(var.sns_delivery_policy))
    error_message = "Invalid JSON for var.sns_delivery_policy"
  }
}

variable "sns_kms_key_id" {
  description = "Existing KMS key to use for encrypting the SNS topic"
  type        = string
  default     = null
}

variable "fifo_topic" {
  description = "Whether or not to make the SNS topic FIFO. Note that FIFO queues only support SQS supscriptions."
  type        = bool
  default     = false
}