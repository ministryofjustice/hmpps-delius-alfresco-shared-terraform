###############################################
# CloudWatch
###############################################
module "create_loggroup" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//cloudwatch//loggroup"
  log_group_path           = "${local.short_environment_identifier}"
  loggroupname             = "gdpr-solr"
  cloudwatch_log_retention = "${var.alf_cloudwatch_log_retention}"
  kms_key_id               = "${local.logs_kms_arn}"
  tags                     = "${local.tags}"
}
