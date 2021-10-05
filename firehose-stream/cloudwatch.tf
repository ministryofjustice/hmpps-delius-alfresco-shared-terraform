###############################################
# CloudWatch
###############################################
module "create_loggroup" {
  source                   = "../modules/cloudwatch/loggroup"
  log_group_path           = local.common_name
  loggroupname             = "streams"
  cloudwatch_log_retention = var.alf_cloudwatch_log_retention
  kms_key_id               = local.logs_kms_arn
  tags                     = local.tags
}

resource "aws_cloudwatch_log_stream" "firehose" {
  name           = "main"
  log_group_name = module.create_loggroup.loggroup_name
}
