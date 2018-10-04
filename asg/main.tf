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
### Getting the common details
#-------------------------------------------------------------
data "terraform_remote_state" "common" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/common/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the s3 details
#-------------------------------------------------------------
data "terraform_remote_state" "s3bucket" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/s3buckets/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the IAM details
#-------------------------------------------------------------
data "terraform_remote_state" "iam" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/iam/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the rds details
#-------------------------------------------------------------
data "terraform_remote_state" "rds" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/rds/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the security groups details
#-------------------------------------------------------------
data "terraform_remote_state" "security-groups" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/security-groups/terraform.tfstate"
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

####################################################
# Locals
####################################################

locals {
  ami_id                         = "${data.aws_ami.amazon_ami.id}"
  account_id                     = "${data.terraform_remote_state.common.common_account_id}"
  vpc_id                         = "${data.terraform_remote_state.common.vpc_id}"
  cidr_block                     = "${data.terraform_remote_state.common.vpc_cidr_block}"
  allowed_cidr_block             = ["${data.terraform_remote_state.common.vpc_cidr_block}"]
  internal_domain                = "${data.terraform_remote_state.common.internal_domain}"
  private_zone_id                = "${data.terraform_remote_state.common.private_zone_id}"
  external_domain                = "${data.terraform_remote_state.common.external_domain}"
  public_zone_id                 = "${data.terraform_remote_state.common.public_zone_id}"
  environment_identifier         = "${data.terraform_remote_state.common.environment_identifier}"
  short_environment_identifier   = "${data.terraform_remote_state.common.short_environment_identifier}"
  region                         = "${var.region}"
  alfresco_app_name              = "${data.terraform_remote_state.common.alfresco_app_name}"
  environment                    = "${data.terraform_remote_state.common.environment}"
  tags                           = "${data.terraform_remote_state.common.common_tags}"
  private_subnet_map             = "${data.terraform_remote_state.common.private_subnet_map}"
  lb_security_groups             = ["${data.terraform_remote_state.security-groups.security_groups_sg_internal_lb_id}"]
  instance_profile               = "${data.terraform_remote_state.iam.iam_policy_int_app_instance_profile_name}"
  access_logs_bucket             = "${data.terraform_remote_state.common.common_s3_lb_logs_bucket}"
  ssh_deployer_key               = "${data.terraform_remote_state.common.common_ssh_deployer_key}"
  s3bucket_kms_id                = "${data.terraform_remote_state.s3bucket.s3bucket_kms_id}"
  s3bucket                       = "${data.terraform_remote_state.s3bucket.s3bucket}"
  db_name                        = "${data.terraform_remote_state.rds.rds_db_instance_database_name}"
  db_username                    = "${data.terraform_remote_state.rds.rds_db_instance_username}"
  db_host                        = "${data.terraform_remote_state.rds.rds_db_instance_endpoint_cname}"
  monitoring_server_internal_url = "${data.terraform_remote_state.common.monitoring_server_internal_url}"
  app_hostnames                  = "${data.terraform_remote_state.common.app_hostnames}"

  instance_security_groups = [
    "${data.terraform_remote_state.security-groups.security_groups_sg_internal_instance_id}",
    "${data.terraform_remote_state.common.common_sg_outbound_id}",
    "${data.terraform_remote_state.common.monitoring_server_client_sg_id}",
  ]
}

####################################################
# ASG - Application Specific
####################################################
module "asg" {
  source                       = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//projects//alfresco//asg"
  alfresco_app_name            = "${local.alfresco_app_name}"
  app_hostnames                = "${local.app_hostnames}"
  environment_identifier       = "${local.environment_identifier}"
  tags                         = "${local.tags}"
  private_subnet_ids           = "${local.private_subnet_map}"
  short_environment_identifier = "${local.short_environment_identifier}"
  instance_profile             = "${local.instance_profile}"
  access_logs_bucket           = "${local.access_logs_bucket}"
  ssh_deployer_key             = "${local.ssh_deployer_key}"
  bucket_kms_key_id            = "${local.s3bucket_kms_id}"
  alfresco_s3bucket            = "${local.s3bucket}"
  lb_security_groups           = ["${local.lb_security_groups}"]
  internal                     = true
  az_asg_desired               = "${var.az_asg_desired}"
  az_asg_min                   = "${var.az_asg_min}"
  az_asg_max                   = "${var.az_asg_max}"
  cloudwatch_log_retention     = "${var.cloudwatch_log_retention}"
  zone_id                      = "${local.private_zone_id}"
  external_domain              = "${local.external_domain}"
  internal_domain              = "${local.internal_domain}"
  db_name                      = "${local.db_name}"
  db_username                  = "${local.db_username}"
  db_host                      = "${local.db_host}"
  environment                  = "${local.environment}"
  region                       = "${local.region}"
  ami_id                       = "${local.ami_id}"
  account_id                   = "${local.account_id}"
  alfresco_instance_ami        = "${var.alfresco_instance_ami}"
  monitoring_server_url        = "${local.monitoring_server_internal_url}"

  listener = [
    {
      instance_port     = "8080"
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    },
  ]

  health_check = [
    {
      target              = "HTTP:8080/alfresco/"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]

  # ASG
  service_desired_count       = "3"
  user_data                   = "../user_data/user_data.sh"
  volume_size                 = "20"
  ebs_device_name             = "/dev/xvdb"
  ebs_volume_type             = "standard"
  ebs_volume_size             = "512"
  ebs_encrypted               = "true"
  instance_type               = "${var.asg_instance_type}"
  associate_public_ip_address = false
  cache_home                  = "/srv/cache"

  instance_security_groups = ["${local.instance_security_groups}"]
}