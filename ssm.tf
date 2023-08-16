resource "aws_ssm_parameter" "current_eks_version_parameter_name" {
  count = var.create_parameters ? 1 : 0

  name  = var.current_eks_version_parameter_name
  type  = "String"
  value = var.current_eks_version
}

resource "aws_ssm_parameter" "versions_parameter_name" {
  count = var.create_parameters ? 1 : 0

  name  = var.versions_parameter_name
  type  = "String"
  value = "{}"

  lifecycle {
    ignore_changes = [value]
  }
}
