resource "aws_cloudwatch_log_group" "environment" {
  name              = "${var.log_group_path}/${var.loggroupname}"
  retention_in_days = var.cloudwatch_log_retention
  kms_key_id        = var.kms_key_id
  tags = merge(
    var.tags,
    {
      "Name" = var.loggroupname
    },
  )
}

