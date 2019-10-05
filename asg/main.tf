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
### Getting the security groups details
#-------------------------------------------------------------
data "terraform_remote_state" "self_certs" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/certs/terraform.tfstate"
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
### Getting the efs details
#-------------------------------------------------------------
data "terraform_remote_state" "efs" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/efs/terraform.tfstate"
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
### Getting the Amazon broker url
#-------------------------------------------------------------
data "terraform_remote_state" "amazonmq" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "spg/amazonmq/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the elk-migration details
#-------------------------------------------------------------
data "terraform_remote_state" "elk_migration" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/elk-migration/terraform.tfstate"
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
### Getting ACM Cert
#-------------------------------------------------------------
data "aws_acm_certificate" "cert" {
  domain      = "*.${data.terraform_remote_state.common.external_domain}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

####################################################
# Locals
####################################################

locals {
  ami_id                         = "${var.alfresco_asg_props["asg_ami"] != "" ? var.alfresco_asg_props["asg_ami"] : data.aws_ami.amazon_ami.id}"
  account_id                     = "${data.terraform_remote_state.common.common_account_id}"
  vpc_id                         = "${data.terraform_remote_state.common.vpc_id}"
  cidr_block                     = "${data.terraform_remote_state.common.vpc_cidr_block}"
  allowed_cidr_block             = ["${data.terraform_remote_state.common.vpc_cidr_block}"]
  internal_domain                = "${data.terraform_remote_state.common.internal_domain}"
  private_zone_id                = "${data.terraform_remote_state.common.private_zone_id}"
  public_zone_id                 = "${data.terraform_remote_state.common.public_zone_id}"
  external_domain                = "${data.terraform_remote_state.common.external_domain}"
  environment_identifier         = "${data.terraform_remote_state.common.environment_identifier}"
  common_name                    = "${data.terraform_remote_state.common.common_name}"
  short_environment_identifier   = "${data.terraform_remote_state.common.short_environment_identifier}"
  region                         = "${var.region}"
  alfresco_app_name              = "${data.terraform_remote_state.common.alfresco_app_name}"
  environment                    = "${data.terraform_remote_state.common.environment}"
  tags                           = "${data.terraform_remote_state.common.common_tags}"
  private_subnet_map             = "${data.terraform_remote_state.common.private_subnet_map}"
  lb_security_groups             = ["${data.terraform_remote_state.security-groups.security_groups_sg_external_lb_id}"]
  instance_profile               = "${data.terraform_remote_state.iam.iam_policy_int_app_instance_profile_name}"
  access_logs_bucket             = "${data.terraform_remote_state.common.common_s3_lb_logs_bucket}"
  ssh_deployer_key               = "${data.terraform_remote_state.common.common_ssh_deployer_key}"
  s3bucket_kms_id                = "${data.terraform_remote_state.s3bucket.s3bucket_kms_id}"
  s3bucket                       = "${data.terraform_remote_state.s3bucket.s3bucket}"
  db_name                        = "${data.terraform_remote_state.rds.rds_creds["db_name"]}"
  db_username_ssm                = "${data.terraform_remote_state.rds.rds_creds["db_username_ssm_param"]}"
  db_password_ssm                = "${data.terraform_remote_state.rds.rds_creds["db_password_ssm_param"]}"
  db_host                        = "${data.terraform_remote_state.rds.rds_db_instance_endpoint_cname}"
  monitoring_server_internal_url = "${data.terraform_remote_state.elk_migration.migration_server_internal_url}"
  app_hostnames                  = "${data.terraform_remote_state.common.app_hostnames}"
  bastion_inventory              = "${var.bastion_inventory}"
  jvm_memory                     = "${var.alfresco_jvm_memory}"
  config-bucket                  = "${data.terraform_remote_state.common.common_s3-config-bucket}"
  tomcat_host                    = "alfresco"
  certificate_arn                = "${data.aws_acm_certificate.cert.arn}"
  public_subnet_ids              = ["${data.terraform_remote_state.common.public_subnet_ids}"]
  messaging_broker_url           = "${var.spg_messaging_broker_url_src == "data" ?
                                    data.terraform_remote_state.amazonmq.amazon_mq_broker_connect_url :
                                    var.spg_messaging_broker_url}"
  messaging_broker_password      = "${data.terraform_remote_state.common.credentials_ssm_path}/weblogic/spg-domain/remote_broker_password"
  logstash_host_fqdn             = "${data.terraform_remote_state.elk_migration.internal_logstash_host}"

  self_signed_ssm = {
    ca_cert = "${data.terraform_remote_state.self_certs.self_signed_ca_ssm_cert_pem_name}"
    cert    = "${data.terraform_remote_state.self_certs.self_signed_server_ssm_cert_pem_name}"
    key     = "${data.terraform_remote_state.self_certs.self_signed_server_ssm_private_key_name}"
  }

  instance_security_groups = [
    "${data.terraform_remote_state.security-groups.security_groups_sg_internal_instance_id}",
    "${data.terraform_remote_state.common.common_sg_outbound_id}",
    "${data.terraform_remote_state.security-groups.security_groups_sg_monitoring_client}",
    "${data.terraform_remote_state.security-groups.security_groups_bastion_in_sg_id}",
    "${data.terraform_remote_state.security-groups.security_groups_map["mon_jenkins"]}"
  ]
}

####################################################
# ASG - Application Specific
####################################################
module "asg" {
  source                       = "../modules/asg"
  alfresco_app_name            = "${local.alfresco_app_name}"
  app_hostnames                = "${local.app_hostnames}"
  environment_identifier       = "${local.environment_identifier}"
  common_name                  = "${local.common_name}"
  tags                         = "${local.tags}"
  private_subnet_ids           = "${local.private_subnet_map}"
  short_environment_identifier = "${local.short_environment_identifier}"
  instance_profile             = "${local.instance_profile}"
  access_logs_bucket           = "${local.access_logs_bucket}"
  ssh_deployer_key             = "${local.ssh_deployer_key}"
  bucket_kms_key_id            = "${local.s3bucket_kms_id}"
  alfresco_s3bucket            = "${local.s3bucket}"
  lb_security_groups           = ["${local.lb_security_groups}"]
  internal                     = false
  az_asg_desired               = "${var.alfresco_asg_props["asg_desired"]}"
  az_asg_min                   = "${var.alfresco_asg_props["asg_min"]}"
  az_asg_max                   = "${var.alfresco_asg_props["asg_max"]}"
  cloudwatch_log_retention     = "${var.cloudwatch_log_retention}"
  zone_id                      = "${local.private_zone_id}"
  external_domain              = "${local.external_domain}"
  internal_domain              = "${local.internal_domain}"
  db_name                      = "${local.db_name}"
  db_username                  = "${local.db_username_ssm}"
  db_password                  = "${local.db_password_ssm}"
  db_host                      = "${local.db_host}"
  environment                  = "${local.environment}"
  region                       = "${local.region}"
  ami_id                       = "${local.ami_id}"
  account_id                   = "${local.account_id}"
  monitoring_server_url        = "${local.monitoring_server_internal_url}"
  logstash_host_fqdn           = "${local.logstash_host_fqdn}"
  messaging_broker_url         = "${local.messaging_broker_url}"
  messaging_broker_password    = "${local.messaging_broker_password}"
  bastion_inventory            = "${local.bastion_inventory}"
  keys_dir                     = "/opt/keys"
  self_signed_ssm              = "${local.self_signed_ssm}"
  config_bucket                = "${local.config-bucket}"
  tomcat_host                  = "${local.tomcat_host}"
  certificate_arn              = "${local.certificate_arn}"
  public_subnet_ids            = ["${local.public_subnet_ids}"]
  public_zone_id               = "${local.public_zone_id}"
  health_check_grace_period    = "${var.alfresco_asg_props["health_check_grace_period"]}"

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    },
  ]

  health_check = [
    {
      target              = "HTTP:80/alfresco/"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]

  # ASG
  service_desired_count       = "3"
  user_data                   = "../user_data/user_data.sh"
  volume_size                 = "${var.alfresco_volume_size}"
  ebs_device_name             = "/dev/xvdb"
  ebs_volume_type             = "standard"
  ebs_volume_size             = "${var.alfresco_asg_props["ebs_volume_size"]}"
  ebs_encrypted               = "true"
  instance_type               = "${var.alfresco_asg_props["asg_instance_type"]}"
  associate_public_ip_address = false
  cache_home                  = "/srv/cache"
  jvm_memory                  = "${local.jvm_memory}"
  instance_security_groups    = ["${local.instance_security_groups}"]
}
