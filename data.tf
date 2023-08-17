data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_ssm_parameter" "current_eks_version" {
  depends_on = [aws_ssm_parameter.current_eks_version_parameter_name]
  name       = var.current_eks_version_parameter_name
}

data "aws_ssm_parameter" "eks_versions" {
  depends_on = [aws_ssm_parameter.versions_parameter_name]
  name       = var.versions_parameter_name
}
