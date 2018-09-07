terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

provider "aws" {
  region  = "${var.region}"
  version = "~> 1.16"
}

####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

#-------------------------------------------------------------
### Getting the current vpc
#-------------------------------------------------------------
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "vpc/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the common details
#-------------------------------------------------------------
data "terraform_remote_state" "common" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "${var.alfresco_app_name}/common/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting IAM roles
#-------------------------------------------------------------
data "terraform_remote_state" "iam" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "${var.alfresco_app_name}/service-alfresco/iam/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting Security Groups
#-------------------------------------------------------------
data "terraform_remote_state" "sgs" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "${var.alfresco_app_name}/service-alfresco/security-groups/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting Monitoring Server
#-------------------------------------------------------------
data "terraform_remote_state" "monitoring-server" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "monitoring-server/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting self signed cert
#-------------------------------------------------------------
data "terraform_remote_state" "self_signed" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "${var.alfresco_app_name}/self-signed/server/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting self signed ca
#-------------------------------------------------------------
data "terraform_remote_state" "self_signed_ca" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "${var.alfresco_app_name}/self-signed/ca/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the latest amazon ami
#-------------------------------------------------------------
data "aws_ami" "amazon_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["HMPPS Alfresco master*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

#-------------------------------------------------------------
### Getting the s3 bucket
#-------------------------------------------------------------

data "terraform_remote_state" "s3-buckets" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "${var.alfresco_app_name}/service-alfresco/s3bucket/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting rds data
#-------------------------------------------------------------
data "terraform_remote_state" "rds" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "${var.alfresco_app_name}/service-alfresco/rds/terraform.tfstate"
    region = "${var.region}"
  }
}

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
  tags                  = "${data.terraform_remote_state.common.common_tags}"
  monitoring_server_url = "test"                                                            #"${data.terraform_remote_state.monitoring-server.monitoring_internal_dns}"

  subnet_ids = [
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az1}",
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az2}",
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az3}",
  ]

  az1_subnet = "${data.terraform_remote_state.vpc.vpc_private-subnet-az1}"

  az2_subnet = "${data.terraform_remote_state.vpc.vpc_private-subnet-az2}"

  az3_subnet = "${data.terraform_remote_state.vpc.vpc_private-subnet-az3}"

  log_groups = ["secure", "messages", "dmesg", "${var.alfresco_app_name}"]

  access_logs_bucket = "${data.terraform_remote_state.common.common_s3_lb_logs_bucket}"

  lb_security_groups = ["${data.terraform_remote_state.sgs.service_alfresco_security_groups_sg_internal_lb_id}"]

  instance_security_groups = [
    "${data.terraform_remote_state.sgs.service_alfresco_security_groups_sg_internal_instance_id}",
    "${data.terraform_remote_state.common.common_sg_outbound_id}",
  ]
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
  name          = "${local.common_prefix}-alfresco-app-cookie-policy"
  load_balancer = "${module.create_app_elb.environment_elb_name}"
  lb_port       = 80
  cookie_name   = "JSESSIONID"
}

###############################################
# Create route53 entry for elb
###############################################

resource "aws_route53_record" "dns_entry" {
  name    = "${local.common_name}.${data.terraform_remote_state.common.common_private_zone_name}"
  type    = "CNAME"
  zone_id = "${data.terraform_remote_state.common.common_private_zone_id}"
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
    route53_sub_domain      = "${data.terraform_remote_state.vpc.environment_name}"
    private_domain          = "${data.terraform_remote_state.common.common_private_zone_name}"
    account_id              = "${data.terraform_remote_state.vpc.vpc_account_id}"
    internal_domain         = "${data.terraform_remote_state.common.common_private_zone_name}"
    monitoring_server_url   = "${local.monitoring_server_url}"
    monitoring_cluster_name = "${var.short_environment_identifier}-es-cluster"
    cluster_subnet          = ""
    cluster_name            = "${var.environment_identifier}-public-ecs-cluster"
    db_name                 = "${data.terraform_remote_state.rds.service_alfresco_rds_db_instance_database_name}"
    db_host                 = "${data.terraform_remote_state.rds.service_alfresco_rds_db_instance_endpoint_cname}"
    db_user                 = "${data.terraform_remote_state.rds.service_alfresco_rds_db_instance_username}"
    db_password             = "${local.db_password}"
    server_mode             = "TEST"

    #s3 config data
    bucket_name         = "${data.terraform_remote_state.s3-buckets.service_alfresco_s3bucket}"
    bucket_encrypt_type = "kms"
    bucket_key_id       = "${data.terraform_remote_state.s3-buckets.service_alfresco_s3bucket_kms_id}"
    external_fqdn       = "${local.common_name}.${data.terraform_remote_state.common.common_private_zone_name}"
  }
}

# ############################################
# # CREATE LAUNCH CONFIG FOR EC2 RUNNING SERVICES
# ############################################

# AZ1 
module "launch_cfg_az1" {
  source                      = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//launch_configuration//blockdevice"
  launch_configuration_name   = "${local.common_label}1"
  image_id                    = "${var.alfresco_instance_ami["az1"] != "" ? var.alfresco_instance_ami["az1"] : data.aws_ami.amazon_ami.id}"
  instance_type               = "${var.instance_type}"
  volume_size                 = "${var.volume_size}"
  instance_profile            = "${data.terraform_remote_state.iam.service_alfresco_iam_policy_int_app_instance_profile_name}"
  key_name                    = "${data.terraform_remote_state.common.common_ssh_deployer_key}"
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
  image_id                    = "${var.alfresco_instance_ami["az2"] != "" ? var.alfresco_instance_ami["az2"] : data.aws_ami.amazon_ami.id}"
  instance_type               = "${var.instance_type}"
  volume_size                 = "${var.volume_size}"
  instance_profile            = "${data.terraform_remote_state.iam.service_alfresco_iam_policy_int_app_instance_profile_name}"
  key_name                    = "${data.terraform_remote_state.common.common_ssh_deployer_key}"
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
  image_id                    = "${var.alfresco_instance_ami["az3"] != "" ? var.alfresco_instance_ami["az3"] : data.aws_ami.amazon_ami.id}"
  instance_type               = "${var.instance_type}"
  volume_size                 = "${var.volume_size}"
  instance_profile            = "${data.terraform_remote_state.iam.service_alfresco_iam_policy_int_app_instance_profile_name}"
  key_name                    = "${data.terraform_remote_state.common.common_ssh_deployer_key}"
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
