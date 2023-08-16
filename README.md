# eks-version-notifier

This module can be used to send notifications about EKS and AMI releases and supports the following notifications:
* EKS Control Plane versions
* AMI Versions for EKS-optimized Amazonlinux 2 (x86_64 and arm64)
* AMI Versions for Bottlerocket (x86_64 and arm64)
* GPU AMI versions for Amazonlinux 2 x86_64 architecture
* Nvidia AMI versions for Amazonlinux 2 versions (for both x86_64 and arm64)

## How it Works
The module deploys a Lambda function with an EventBridge Scheduled Event Rule. When the Lambda fires it:
* Reads SSM Parameter Store for what you specify as your current EKS version
* Uses AWS's public SSM entries to retreive the latest AMI ID for the flavor that you have configured
* Uses `describe_addons` from boto3's EKS client to parse out the available EKS versions and stores them along with the latest AMI ID's retreived in the previous step
* Sends a notification over SNS or SES to a specified destination when a newer version than what you have declared as your current EKS version is available
* Sends a notification if the latest AMI for your current EKS version is updated
* SNS and SES can be turned off individually, in which case you just get logs

Example `terraform.tfvars`:

```
send_email                         = false
publish_sns                        = false
versions_parameter_name            = "EKS_BOTTLEROCKET_VERSIONS"
create_parameters                  = true
current_eks_version_parameter_name = "EKS_BOTTLEROCKET_CURRENT_VERSION"
bottlerocket                       = true
architecture                       = "arm64"
gpu                                = true
sns_topic_name                     = "eks-version-notifications"
from_address                       = "example@must-be-validated-with-ses.com"
to_address                         = "your-email@somewhere.com"
lambda_name                        = "eks-versions-test"
notify_ami                         = true
notify_eks                         = true
current_eks_version                = "1.24"
log_level                          = "INFO"
```

Note that either the email address or domain for `var.send_from` must be verified with SES before it can send an email.
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.52 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.4.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.12.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_sns_topic.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_ssm_parameter.current_eks_version_parameter_name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.versions_parameter_name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_iam_policy_document.lambda_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_architecture"></a> [architecture](#input\_architecture) | The architecture for the AMI. If var.bottlerocket is `false` then this is mutually exclusive with var.gpu | `string` | `"x86_64"` | no |
| <a name="input_bottlerocket"></a> [bottlerocket](#input\_bottlerocket) | Whether or not to use Bottlerocket AMI | `bool` | `true` | no |
| <a name="input_create_parameters"></a> [create\_parameters](#input\_create\_parameters) | If `true` then create the parameters | `any` | n/a | yes |
| <a name="input_current_eks_version"></a> [current\_eks\_version](#input\_current\_eks\_version) | The current EKS version to check for new versions above and AMI versions for | `string` | n/a | yes |
| <a name="input_current_eks_version_parameter_name"></a> [current\_eks\_version\_parameter\_name](#input\_current\_eks\_version\_parameter\_name) | Name to use for storing current EKS version | `string` | n/a | yes |
| <a name="input_fifo_topic"></a> [fifo\_topic](#input\_fifo\_topic) | Whether or not to make the SNS topic FIFO. Note that FIFO queues only support SQS supscriptions. | `bool` | `false` | no |
| <a name="input_from_address"></a> [from\_address](#input\_from\_address) | The From address to use with SES | `string` | `""` | no |
| <a name="input_gpu"></a> [gpu](#input\_gpu) | Use GPU AMI. If var.bottlerocket is `false` then this is mutually exclusive with var.architecture | `bool` | `false` | no |
| <a name="input_lambda_log_retention_days"></a> [lambda\_log\_retention\_days](#input\_lambda\_log\_retention\_days) | Retention in days to apply to the Function's Cloudwatch log | `number` | `14` | no |
| <a name="input_lambda_memory_size"></a> [lambda\_memory\_size](#input\_lambda\_memory\_size) | The amount of RAM to allocate to the function | `number` | `1024` | no |
| <a name="input_lambda_name"></a> [lambda\_name](#input\_lambda\_name) | Name for the newly created Lambda | `string` | n/a | yes |
| <a name="input_lambda_timeout"></a> [lambda\_timeout](#input\_lambda\_timeout) | The timeout for the function in seconds | `number` | `30` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Log level for Lambda function | `string` | n/a | yes |
| <a name="input_notify_ami"></a> [notify\_ami](#input\_notify\_ami) | Whether the function should actually send notifications for AMI updates | `bool` | `false` | no |
| <a name="input_notify_eks"></a> [notify\_eks](#input\_notify\_eks) | Whether the function should actually send notifications for EKS versions | `bool` | `false` | no |
| <a name="input_publish_sns"></a> [publish\_sns](#input\_publish\_sns) | Whether to publish to SNS topic | `any` | n/a | yes |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | A valid CloudWatch schedule expression that will be used for triggering the Lambda | `string` | `"rate(12 hours)"` | no |
| <a name="input_send_email"></a> [send\_email](#input\_send\_email) | Whether to send email via SES | `string` | `null` | no |
| <a name="input_sns_delivery_policy"></a> [sns\_delivery\_policy](#input\_sns\_delivery\_policy) | Deliver policy for created SNS topics | `string` | `null` | no |
| <a name="input_sns_kms_key_id"></a> [sns\_kms\_key\_id](#input\_sns\_kms\_key\_id) | Existing KMS key to use for encrypting the SNS topic | `string` | `null` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | The ARN of an existing SNS topic to publish to. Mutually exclusive to var.sns\_topic\_name | `string` | `null` | no |
| <a name="input_sns_topic_name"></a> [sns\_topic\_name](#input\_sns\_topic\_name) | Name for SNS topic to create. Mutually exclusive to var.sns\_topic\_arn | `string` | `null` | no |
| <a name="input_sns_topic_policy"></a> [sns\_topic\_policy](#input\_sns\_topic\_policy) | A policy to attach to the created SNS topic. Cannot be used when specifying an existing topic using var.sns\_topic\_arn | `string` | `null` | no |
| <a name="input_to_address"></a> [to\_address](#input\_to\_address) | The To address to use with SES | `string` | `""` | no |
| <a name="input_versions_parameter_name"></a> [versions\_parameter\_name](#input\_versions\_parameter\_name) | Name to use for storing EKS and corresponding AMI versions | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eventbridge_rule_arn"></a> [eventbridge\_rule\_arn](#output\_eventbridge\_rule\_arn) | The ARN of the EventBridge Rule that triggers Lambda |
| <a name="output_function_arn"></a> [function\_arn](#output\_function\_arn) | The ARN of the Lambda function |
| <a name="output_lambda_iam_policy"></a> [lambda\_iam\_policy](#output\_lambda\_iam\_policy) | The actial IAM policy json for the Lambda function |
| <a name="output_lambda_role_arn"></a> [lambda\_role\_arn](#output\_lambda\_role\_arn) | The ARN of the role attached to the Lambda function |
| <a name="output_schedule_expression"></a> [schedule\_expression](#output\_schedule\_expression) | The Cloudwatch schedule expression applied to the EventBridge rule to run the Lambda |
| <a name="output_sns_topic"></a> [sns\_topic](#output\_sns\_topic) | The SNS topic that new versions are sent to |
| <a name="output_sns_topic_policy"></a> [sns\_topic\_policy](#output\_sns\_topic\_policy) | The resource policy applied to the SNS topic |
<!-- END_TF_DOCS -->