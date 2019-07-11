####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

locals {
  ############################################  # LOCALS  ############################################

  common_name               = "${var.app_hostnames["internal"]}"
  application_endpoint      = "${var.app_hostnames["external"]}"
  lb_name                   = "${var.short_environment_identifier}-app"
  common_label              = "${var.common_name}"
  common_prefix             = "${var.environment_identifier}"
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

  az1_subnet = "${var.private_subnet_ids["az1"]}"

  az2_subnet = "${var.private_subnet_ids["az2"]}"

  az3_subnet = "${var.private_subnet_ids["az3"]}"

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

###############################################
# CloudWatch
###############################################
module "create_loggroup" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//cloudwatch//loggroup"
  log_group_path           = "${var.environment_identifier}"
  loggroupname             = "${local.common_name}"
  cloudwatch_log_retention = "${var.cloudwatch_log_retention}"
  tags                     = "${local.tags}"
}

# ############################################
# # CREATE USER DATA FOR EC2 RUNNING SERVICES
# ############################################

data "template_file" "user_data" {
  template = "${file("${var.user_data}")}"

  vars {
    env_identifier            = "${var.environment_identifier}"
    short_env_identifier      = "${var.short_environment_identifier}"
    app_name                  = "${var.alfresco_app_name}"
    cldwatch_log_group        = "${module.create_loggroup.loggroup_name}"
    region                    = "${var.region}"
    cache_home                = "${var.cache_home}"
    ebs_device                = "${var.ebs_device_name}"
    app_name                  = "${var.alfresco_app_name}"
    route53_sub_domain        = "${var.alfresco_app_name}.${var.environment}"
    private_domain            = "${var.internal_domain}"
    account_id                = "${var.account_id}"
    internal_domain           = "${var.internal_domain}"
    monitoring_server_url     = "${local.monitoring_server_url}"
    monitoring_cluster_name   = "${var.short_environment_identifier}-es-cluster"
    cluster_subnet            = ""
    cluster_name              = "${var.environment_identifier}-public-ecs-cluster"
    db_name                   = "${local.db_name}"
    db_host                   = "${local.db_host}"
    db_user                   = "${local.db_username}"
    db_password               = "${local.db_password}"
    server_mode               = "TEST"
    keys_dir                  = "${var.keys_dir}"
    image_url                 = "${var.image_url}"
    image_version             = "${var.image_version}"
    tomcat_host               = "${var.tomcat_host}"
    tomcat_port               = "${var.tomcat_port}"
    config_file_path          = "${local.common_name}/config/nginx.conf"
    nginx_config_file         = "/etc/nginx/conf.d/app.conf"
    s3_bucket_config          = "${local.config_bucket}"
    runtime_config_override   = "s3"
    self_signed_ca_cert       = "${var.self_signed_ssm["ca_cert"]}"
    self_signed_cert          = "${var.self_signed_ssm["cert"]}"
    self_signed_key           = "${var.self_signed_ssm["key"]}"
    ssm_get_command           = "aws --region ${var.region} ssm get-parameters --names"
    messaging_broker_url      = "${var.messaging_broker_url}"
    logstash_host_fqdn        = "${var.logstash_host_fqdn}"
    messaging_broker_password = "${local.messaging_broker_password}"

    #s3 config data
    bucket_name         = "${var.alfresco_s3bucket}"
    bucket_encrypt_type = "kms"
    bucket_key_id       = "${var.bucket_kms_key_id}"
    external_fqdn       = "${var.app_hostnames["external"]}.${var.external_domain}"
    jvm_memory          = "${var.jvm_memory}"

    # For bootstrapping
    bastion_inventory = "${var.bastion_inventory}"
  }
}

# ############################################
# # CREATE LAUNCH CONFIG FOR EC2 RUNNING SERVICES
# ############################################

# AZ1 
module "launch_cfg_az1" {
  source                      = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//launch_configuration//blockdevice"
  launch_configuration_name   = "${local.common_label}-az1"
  image_id                    = "${var.alfresco_instance_ami["az1"] != "" ? var.alfresco_instance_ami["az1"] : var.ami_id}"
  instance_type               = "${var.instance_type}"
  volume_size                 = "${var.volume_size}"
  instance_profile            = "${var.instance_profile}"
  key_name                    = "${var.ssh_deployer_key}"
  ebs_device_name             = "${var.ebs_device_name}"
  ebs_volume_type             = "${var.ebs_volume_type}"
  ebs_volume_size             = "${var.ebs_volume_size}"
  ebs_encrypted               = "${var.ebs_encrypted}"
  associate_public_ip_address = "${var.associate_public_ip_address}"

  security_groups = [
    "${local.instance_security_groups}",
  ]

  user_data = "${data.template_file.user_data.rendered}"
}

#AZ2
module "launch_cfg_az2" {
  source                      = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//launch_configuration//blockdevice"
  launch_configuration_name   = "${local.common_label}-az2"
  image_id                    = "${var.alfresco_instance_ami["az2"] != "" ? var.alfresco_instance_ami["az2"] : var.ami_id}"
  instance_type               = "${var.instance_type}"
  volume_size                 = "${var.volume_size}"
  instance_profile            = "${var.instance_profile}"
  key_name                    = "${var.ssh_deployer_key}"
  ebs_device_name             = "${var.ebs_device_name}"
  ebs_volume_type             = "${var.ebs_volume_type}"
  ebs_volume_size             = "${var.ebs_volume_size}"
  ebs_encrypted               = "${var.ebs_encrypted}"
  associate_public_ip_address = "${var.associate_public_ip_address}"

  security_groups = [
    "${local.instance_security_groups}",
  ]

  user_data = "${data.template_file.user_data.rendered}"
}

#AZ3
module "launch_cfg_az3" {
  source                      = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//launch_configuration//blockdevice"
  launch_configuration_name   = "${local.common_label}-az3"
  image_id                    = "${var.alfresco_instance_ami["az3"] != "" ? var.alfresco_instance_ami["az3"] : var.ami_id}"
  instance_type               = "${var.instance_type}"
  volume_size                 = "${var.volume_size}"
  instance_profile            = "${var.instance_profile}"
  key_name                    = "${var.ssh_deployer_key}"
  ebs_device_name             = "${var.ebs_device_name}"
  ebs_volume_type             = "${var.ebs_volume_type}"
  ebs_volume_size             = "${var.ebs_volume_size}"
  ebs_encrypted               = "${var.ebs_encrypted}"
  associate_public_ip_address = "${var.associate_public_ip_address}"

  security_groups = [
    "${local.instance_security_groups}",
  ]

  user_data = "${data.template_file.user_data.rendered}"
}

# ############################################
# # CREATE AUTO SCALING GROUP
# ############################################

#AZ1
module "auto_scale_az1" {
  source               = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//autoscaling//group//asg_classic_lb"
  asg_name             = "${local.common_label}-az1"
  subnet_ids           = ["${local.az1_subnet}"]
  asg_min              = "${var.az_asg_min["az1"]}"
  asg_max              = "${var.az_asg_max["az1"]}"
  asg_desired          = "${var.az_asg_desired["az1"]}"
  launch_configuration = "${module.launch_cfg_az1.launch_name}"
  load_balancers       = ["${module.create_app_elb.environment_elb_name}"]
  tags                 = "${local.tags}"
}

#AZ2
module "auto_scale_az2" {
  source               = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//autoscaling//group//asg_classic_lb"
  asg_name             = "${local.common_label}-az2"
  subnet_ids           = ["${local.az2_subnet}"]
  asg_min              = "${var.az_asg_min["az2"]}"
  asg_max              = "${var.az_asg_max["az2"]}"
  asg_desired          = "${var.az_asg_desired["az2"]}"
  launch_configuration = "${module.launch_cfg_az2.launch_name}"
  load_balancers       = ["${module.create_app_elb.environment_elb_name}"]
  tags                 = "${local.tags}"
}

#AZ3
module "auto_scale_az3" {
  source               = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//autoscaling//group//asg_classic_lb"
  asg_name             = "${local.common_label}-az3"
  subnet_ids           = ["${local.az3_subnet}"]
  asg_min              = "${var.az_asg_min["az3"]}"
  asg_max              = "${var.az_asg_max["az3"]}"
  asg_desired          = "${var.az_asg_desired["az3"]}"
  launch_configuration = "${module.launch_cfg_az3.launch_name}"
  load_balancers       = ["${module.create_app_elb.environment_elb_name}"]
  tags                 = "${local.tags}"
}
