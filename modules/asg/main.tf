####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

locals {
  ############################################  # LOCALS  ############################################

  common_name               = var.app_hostnames["internal"]
  application_endpoint      = var.app_hostnames["external"]
  common_prefix             = "${var.short_environment_identifier}-alf"
  db_name                   = var.db_name
  db_username               = var.db_username
  db_password               = var.db_password
  db_host                   = var.db_host
  tags                      = var.tags
  config_bucket             = var.config_bucket

  subnet_ids = [
    var.private_subnet_ids["az1"],
    var.private_subnet_ids["az2"],
    var.private_subnet_ids["az3"],
  ]

  log_groups = ["secure", "messages", "dmesg", var.alfresco_app_name]

  access_logs_bucket = var.access_logs_bucket

  lb_security_groups = [var.lb_security_groups]

  instance_security_groups = [var.instance_security_groups]
  public_subnet_ids        = [var.public_subnet_ids]
  certificate_arn          = var.certificate_arn
  external_domain          = var.external_domain
  public_zone_id           = var.public_zone_id
}

###############################################
# CloudWatch
###############################################
module "create_loggroup" {
  source                   = "../cloudwatch/loggroup"
  log_group_path           = var.environment_identifier
  loggroupname             = local.common_name
  cloudwatch_log_retention = var.cloudwatch_log_retention
  kms_key_id               = var.logs_kms_arn
  tags                     = local.tags
}

