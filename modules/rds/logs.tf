locals {
  aws_logs_prefix = "/aws/rds/instance/${local.common_name}"
}


resource "aws_cloudwatch_log_group" "log_exports" {
  name              = "${local.aws_logs_prefix}/${element(var.enabled_cloudwatch_logs_exports, count.index)}"
  retention_in_days = "${var.cloudwatch_log_retention}"
  kms_key_id        = "${var.logs_kms_arn}"
  count             = "${length(var.enabled_cloudwatch_logs_exports)}"
  tags              = "${local.tags}"
}
