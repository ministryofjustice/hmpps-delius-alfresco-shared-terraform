####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

#-------------------------------------------------------------
### Getting the rds db password
#-------------------------------------------------------------
data "aws_ssm_parameter" "db_password" {
  name = "${var.environment_identifier}-${var.alfresco_app_name}-rds-db-password"
}

############################################
# LOCALS
############################################

locals {
  common_name           = "${var.alfresco_app_name}-az"
  lb_name               = "${var.short_environment_identifier}-${var.alfresco_app_name}-az"
  common_label          = "${var.environment_identifier}-${var.alfresco_app_name}-az"
  common_prefix         = "${var.environment_identifier}-${var.alfresco_app_name}"
  db_password           = "${data.aws_ssm_parameter.db_password.value}"
  tags                  = "${var.tags}"
  monitoring_server_url = "test"                                                            #"${data.terraform_remote_state.monitoring-server.monitoring_internal_dns}"

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
}

############################################
# CREATE ELB FOR ALFRESCO
############################################

module "create_app_elb" {
  source          = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//loadbalancer//elb//create_elb"
  name            = "${local.lb_name}"
  subnets         = ["${local.subnet_ids}"]
  security_groups = ["${local.lb_security_groups}"]
  internal        = "${var.internal}"

  cross_zone_load_balancing   = "${var.cross_zone_load_balancing}"
  idle_timeout                = "${var.idle_timeout}"
  connection_draining         = "${var.connection_draining}"
  connection_draining_timeout = "${var.connection_draining_timeout}"
  bucket                      = "${local.access_logs_bucket}"
  bucket_prefix               = "${local.lb_name}"
  interval                    = 60
  listener                    = ["${var.listener}"]
  health_check                = ["${var.health_check}"]

  tags = "${local.tags}"
}

resource "aws_app_cookie_stickiness_policy" "alfresco_app_cookie_policy" {
  name          = "${local.common_prefix}-app-cookie-policy"
  load_balancer = "${module.create_app_elb.environment_elb_name}"
  lb_port       = 80
  cookie_name   = "JSESSIONID"
}

###############################################
# Create route53 entry for elb
###############################################

resource "aws_route53_record" "dns_entry" {
  name    = "${local.common_name}.${var.internal_domain}"
  type    = "CNAME"
  zone_id = "${var.zone_id}"
  ttl     = 300
  records = ["${module.create_app_elb.environment_elb_dns_name}"]
}

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
    env_identifier          = "${var.environment_identifier}"
    short_env_identifier    = "${var.short_environment_identifier}"
    app_name                = "${var.alfresco_app_name}"
    cldwatch_log_group      = "${module.create_loggroup.loggroup_name}"
    region                  = "${var.region}"
    cache_home              = "${var.cache_home}"
    ebs_device              = "${var.ebs_device_name}"
    app_name                = "${var.alfresco_app_name}"
    route53_sub_domain      = "${var.alfresco_app_name}.${var.environment}"
    private_domain          = "${var.internal_domain}"
    account_id              = "${var.account_id}"
    internal_domain         = "${var.internal_domain}"
    monitoring_server_url   = "${local.monitoring_server_url}"
    monitoring_cluster_name = "${var.short_environment_identifier}-es-cluster"
    cluster_subnet          = ""
    cluster_name            = "${var.environment_identifier}-public-ecs-cluster"
    db_name                 = "${var.db_name}"
    db_host                 = "${var.db_host}"
    db_user                 = "${var.db_username}"
    db_password             = "${local.db_password}"
    server_mode             = "TEST"

    #s3 config data
    bucket_name         = "${var.alfresco_s3bucket}"
    bucket_encrypt_type = "kms"
    bucket_key_id       = "${var.bucket_kms_key_id}"
    external_fqdn       = "${local.common_name}.${var.internal_domain}"
  }
}

# ############################################
# # CREATE LAUNCH CONFIG FOR EC2 RUNNING SERVICES
# ############################################

# AZ1 
module "launch_cfg_az1" {
  source                      = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//launch_configuration//blockdevice"
  launch_configuration_name   = "${local.common_label}1"
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
  source                      = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//launch_configuration//blockdevice"
  launch_configuration_name   = "${local.common_label}2"
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
  source                      = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//launch_configuration//blockdevice"
  launch_configuration_name   = "${local.common_label}3"
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
  source               = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//autoscaling//group//asg_classic_lb"
  asg_name             = "${local.common_label}1"
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
  source               = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//autoscaling//group//asg_classic_lb"
  asg_name             = "${local.common_label}2"
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
  source               = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//autoscaling//group//asg_classic_lb"
  asg_name             = "${local.common_label}3"
  subnet_ids           = ["${local.az3_subnet}"]
  asg_min              = "${var.az_asg_min["az3"]}"
  asg_max              = "${var.az_asg_max["az3"]}"
  asg_desired          = "${var.az_asg_desired["az3"]}"
  launch_configuration = "${module.launch_cfg_az3.launch_name}"
  load_balancers       = ["${module.create_app_elb.environment_elb_name}"]
  tags                 = "${local.tags}"
}
