# LOCALS 

locals {
  common_name              = "${var.common_name}-${var.app_name}"
  application_endpoint     = "${var.app_hostnames["external"]}"
  lb_name                  = "${var.short_environment_identifier}-${var.app_name}"
  vpc_id                   = "${var.vpc_id}"
  config_bucket            = "${var.config_bucket}"
  public_subnet_ids        = ["${var.public_subnet_ids}"]
  private_subnet_ids       = ["${var.private_subnet_ids}"]
  lb_security_groups       = ["${var.lb_security_groups}"]
  certificate_arn          = "${var.certificate_arn}"
  access_logs_bucket       = "${var.access_logs_bucket}"
  public_zone_id           = "${var.public_zone_id}"
  external_domain          = "${var.external_domain}"
  internal_domain          = "${var.internal_domain}"
  instance_security_groups = ["${var.instance_security_groups}"]
}

############################################
# CREATE LB FOR NGINX
############################################

# elb
module "create_app_elb" {
  source          = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//loadbalancer//elb//create_elb_with_https"
  name            = "${local.lb_name}-ext"
  subnets         = ["${local.public_subnet_ids}"]
  security_groups = ["${local.lb_security_groups}"]
  internal        = "${var.internal}"

  cross_zone_load_balancing   = "${var.cross_zone_load_balancing}"
  idle_timeout                = "${var.idle_timeout}"
  connection_draining         = "${var.connection_draining}"
  connection_draining_timeout = "${var.connection_draining_timeout}"
  bucket                      = "${local.access_logs_bucket}"
  bucket_prefix               = "${local.lb_name}"
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

###############################################
# Create route53 entry for nginx lb
###############################################

resource "aws_route53_record" "dns_entry" {
  zone_id = "${local.public_zone_id}"
  name    = "${local.application_endpoint}.${local.external_domain}"
  type    = "A"

  alias {
    name                   = "${module.create_app_elb.environment_elb_dns_name}"
    zone_id                = "${module.create_app_elb.environment_elb_zone_id}"
    evaluate_target_health = false
  }
}

############################################
# CREATE LOG GROUPS FOR CONTAINER LOGS
############################################

module "create_loggroup" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//cloudwatch//loggroup"
  log_group_path           = "${var.environment_identifier}"
  loggroupname             = "${var.app_name}-${local.application_endpoint}-proxy"
  cloudwatch_log_retention = "${var.cloudwatch_log_retention}"
  tags                     = "${var.tags}"
}

############################################
# CREATE USER DATA FOR EC2 RUNNING SERVICES
############################################

data "template_file" "user_data" {
  template = "${file("${var.user_data}")}"

  vars {
    keys_dir                = "${var.cache_home}"
    ebs_device              = "${var.ebs_device_name}"
    app_name                = "${var.app_name}"
    env_identifier          = "${var.environment_identifier}"
    short_env_identifier    = "${var.short_environment_identifier}"
    log_group_name          = "${module.create_loggroup.loggroup_name}"
    container_name          = "${var.app_name}"
    keys_dir                = "${var.keys_dir}"
    image_url               = "${var.image_url}"
    image_version           = "${var.image_version}"
    self_signed_ca_cert     = "${var.self_signed_ssm["ca_cert"]}"
    self_signed_cert        = "${var.self_signed_ssm["cert"]}"
    self_signed_key         = "${var.self_signed_ssm["key"]}"
    ssm_get_command         = "aws --region ${var.region} ssm get-parameters --names"
    alfresco_host           = "${aws_route53_record.dns_entry.fqdn}"
    config_file_path        = "${local.common_name}/config/nginx.conf"
    nginx_config_file       = "/etc/nginx/conf.d/app.conf"
    runtime_config_override = "s3"
    tomcat_host             = "${var.app_hostnames["internal"]}.${local.internal_domain}"
    kibana_host             = "${var.kibana_host}"
    s3_bucket_config        = "${local.config_bucket}"
    external_domain         = "${local.external_domain}"
    internal_domain         = "${local.internal_domain}"
    route53_sub_domain      = "${var.app_name}.${var.environment}"
    bastion_inventory       = "${var.environment}"
    account_id              = "${var.account_id}"
  }
}

############################################
# CREATE LAUNCH CONFIG FOR EC2 RUNNING SERVICES
############################################

module "launch_cfg" {
  source                      = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//launch_configuration//blockdevice"
  launch_configuration_name   = "${local.common_name}"
  image_id                    = "${var.ami_id}"
  instance_type               = "${var.instance_type}"
  volume_size                 = "${var.volume_size}"
  instance_profile            = "${var.instance_profile}"
  key_name                    = "${var.ssh_deployer_key}"
  ebs_device_name             = "${var.ebs_device_name}"
  ebs_volume_type             = "${var.ebs_volume_type}"
  ebs_volume_size             = "${var.ebs_volume_size}"
  ebs_encrypted               = "${var.ebs_encrypted}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  security_groups             = ["${local.instance_security_groups}"]
  user_data                   = "${data.template_file.user_data.rendered}"
}

############################################
# CREATE AUTO SCALING GROUP
############################################

module "auto_scale" {
  source               = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//autoscaling//group//asg_classic_lb"
  asg_name             = "${local.common_name}"
  subnet_ids           = ["${local.private_subnet_ids}"]
  asg_min              = "${var.asg_min}"
  asg_max              = "${var.asg_max}"
  asg_desired          = "${var.asg_desired}"
  launch_configuration = "${module.launch_cfg.launch_name}"
  load_balancers       = ["${module.create_app_elb.environment_elb_name}"]
  tags                 = "${var.tags}"
}

############################################
# UPLOAD TO S3
############################################

resource "aws_s3_bucket_object" "nginx_bucket_object" {
  key    = "${local.common_name}/config/nginx.conf"
  bucket = "${local.config_bucket}"
  source = "./templates/nginx.conf"
  etag   = "${md5(file("./templates/nginx.conf"))}"
}
