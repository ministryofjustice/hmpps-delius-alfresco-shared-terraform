####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

locals {
  ############################################  # LOCALS  ############################################

  common_name               = "${var.app_hostnames["internal"]}"
  application_endpoint      = "${var.app_hostnames["external"]}"
  common_prefix             = "${var.short_environment_identifier}-alf"
  db_name                   = "${var.db_name}"
  db_username               = "${var.db_username}"
  db_password               = "${var.db_password}"
  db_host                   = "${var.db_host}"
  messaging_broker_password = "${var.messaging_broker_password}"
  tags                      = "${var.tags}"
  monitoring_server_url     = "${var.monitoring_server_url}"
  config_bucket             = "${var.config_bucket}"

  subnet_ids = [
    "${var.private_subnet_ids["az1"]}",
    "${var.private_subnet_ids["az2"]}",
    "${var.private_subnet_ids["az3"]}",
  ]

  log_groups = ["secure", "messages", "dmesg", "${var.alfresco_app_name}"]

  access_logs_bucket = "${var.access_logs_bucket}"

  lb_security_groups = ["${var.lb_security_groups}"]

  instance_security_groups = ["${var.instance_security_groups}"]
  public_subnet_ids        = ["${var.public_subnet_ids}"]
  certificate_arn          = "${var.certificate_arn}"
  external_domain          = "${var.external_domain}"
  public_zone_id           = "${var.public_zone_id}"
}

############################################
# CREATE LB FOR NGINX
############################################

# elb
module "create_app_elb" {
  source          = "../elb/create_elb_with_https"
  name            = "${local.common_prefix}-pub"
  subnets         = ["${local.public_subnet_ids}"]
  security_groups = ["${local.lb_security_groups}"]
  internal        = "${var.internal}"

  cross_zone_load_balancing   = "${var.cross_zone_load_balancing}"
  idle_timeout                = "${var.idle_timeout}"
  connection_draining         = "${var.connection_draining}"
  connection_draining_timeout = "${var.connection_draining_timeout}"
  bucket                      = "${local.access_logs_bucket}"
  bucket_prefix               = "${local.common_prefix}"
  interval                    = 60
  ssl_certificate_id          = "${local.certificate_arn}"
  instance_port               = 80
  instance_protocol           = "http"
  lb_port                     = 80
  lb_port_https               = 443
  lb_protocol                 = "http"
  lb_protocol_https           = "https"
  health_check                = ["${var.health_check}"]
  tags                        = "${var.tags}"
}

resource "aws_app_cookie_stickiness_policy" "alfresco_app_cookie_policy" {
  name          = "${local.common_prefix}-app-cookie-policy"
  load_balancer = "${module.create_app_elb.environment_elb_name}"
  lb_port       = 80
  cookie_name   = "JSESSIONID"
}

resource "aws_app_cookie_stickiness_policy" "alfresco_app_cookie_policy_https" {
  name          = "${local.common_prefix}-app-cookie-policy-https"
  load_balancer = "${module.create_app_elb.environment_elb_name}"
  lb_port       = 443
  cookie_name   = "JSESSIONID"
}

###############################################
# CloudWatch
###############################################
module "create_loggroup" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//cloudwatch//loggroup"
  log_group_path           = "${var.environment_identifier}"
  loggroupname             = "${local.common_name}"
  cloudwatch_log_retention = "${var.cloudwatch_log_retention}"
  kms_key_id               = "${var.logs_kms_arn}"
  tags                     = "${local.tags}"
}
