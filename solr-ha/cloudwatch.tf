###############################################
# CloudWatch
###############################################
module "create_loggroup" {
  source                   = "../modules/cloudwatch/loggroup"
  log_group_path           = local.short_environment_identifier
  loggroupname             = "solr-ha"
  cloudwatch_log_retention = var.alf_cloudwatch_log_retention
  kms_key_id               = local.logs_kms_arn
  tags                     = local.tags
}

