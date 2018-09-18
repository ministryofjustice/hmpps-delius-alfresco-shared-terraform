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
### Getting current
#-------------------------------------------------------------
data "aws_region" "current" {}

#-------------------------------------------------------------
### Getting the vpc details
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
### Getting the monitoring instance details
#-------------------------------------------------------------
data "terraform_remote_state" "monitor" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "shared-monitoring/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the engineering ecr repos
#-------------------------------------------------------------
data "terraform_remote_state" "ecr" {
  backend = "s3"

  config {
    bucket   = "${var.eng-remote_state_bucket_name}"
    key      = "ecr/terraform.tfstate"
    region   = "${var.region}"
    role_arn = "${var.eng_role_arn}"
  }
}

#-------------------------------------------------------------
### Getting the engineer vpc
#-------------------------------------------------------------
data "terraform_remote_state" "remote_vpc" {
  backend = "s3"

  config {
    bucket   = "${var.eng-remote_state_bucket_name}"
    key      = "vpc/terraform.tfstate"
    region   = "${var.region}"
    role_arn = "${var.eng_role_arn}"
  }
}

#-------------------------------------------------------------
### Getting the alfresco IAM role
#-------------------------------------------------------------
data "terraform_remote_state" "remote_iam" {
  backend = "s3"

  config {
    bucket   = "${var.eng-remote_state_bucket_name}"
    key      = "alfresco/iam/terraform.tfstate"
    region   = "${var.region}"
    role_arn = "${var.eng_role_arn}"
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
  vpc_id                         = "${data.terraform_remote_state.vpc.vpc_id}"
  cidr_block                     = "${data.terraform_remote_state.vpc.vpc_cidr_block}"
  allowed_cidr_block             = ["${data.terraform_remote_state.vpc.vpc_cidr_block}"]
  internal_domain                = "${data.terraform_remote_state.vpc.private_zone_name}"
  private_zone_id                = "${data.terraform_remote_state.vpc.private_zone_id}"
  external_domain                = "${data.terraform_remote_state.vpc.public_zone_name}"
  public_zone_id                 = "${data.terraform_remote_state.vpc.public_zone_id}"
  common_name                    = "${var.environment_identifier}-${var.alfresco_app_name}"
  lb_account_id                  = "${var.lb_account_id}"
  region                         = "${var.region}"
  role_arn                       = "${var.role_arn}"
  alfresco_app_name              = "${var.alfresco_app_name}"
  environment_identifier         = "${var.environment_identifier}"
  short_environment_identifier   = "${var.short_environment_identifier}"
  remote_state_bucket_name       = "${var.remote_state_bucket_name}"
  s3_lb_policy_file              = "policies/s3_alb_policy.json"
  environment                    = "${var.environment}"
  tags                           = "${merge(data.terraform_remote_state.vpc.tags, map("sub-project", "${var.alfresco_app_name}"))}"
  aws_ecr_arn                    = "${data.terraform_remote_state.ecr.ecr_repo_repository_arn_alfresco}"
  remote_iam_role                = "${data.terraform_remote_state.remote_iam.alfresco_iam_arn}"
  remote_config_bucket           = "${data.terraform_remote_state.remote_vpc.s3-config-bucket}"
  monitoring_server_external_url = "${data.terraform_remote_state.monitor.monitoring_server_external_url}"
  monitoring_server_internal_url = "${data.terraform_remote_state.monitor.monitoring_server_internal_url}"
  monitoring_server_client_sg_id = "${data.terraform_remote_state.monitor.monitoring_server_client_sg_id}"

  private_subnet_map = {
    az1 = "${data.terraform_remote_state.vpc.vpc_private-subnet-az1}"
    az2 = "${data.terraform_remote_state.vpc.vpc_private-subnet-az2}"
    az3 = "${data.terraform_remote_state.vpc.vpc_private-subnet-az3}"
  }

  public_cidr_block = [
    "${data.terraform_remote_state.vpc.vpc_public-subnet-az1-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_public-subnet-az2-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_public-subnet-az3-cidr_block}",
  ]

  private_cidr_block = [
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az1-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az2-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az3-cidr_block}",
  ]

  db_cidr_block = [
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az1-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az2-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az3-cidr_block}",
  ]

  db_subnet_ids = [
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az1}",
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az2}",
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az3}",
  ]
}

####################################################
# Common
####################################################
module "common" {
  source                       = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=issue-62//projects//alfresco//common"
  alfresco_app_name            = "${local.alfresco_app_name}"
  cidr_block                   = "${local.cidr_block}"
  common_name                  = "${local.common_name}"
  environment                  = "${local.environment}"
  environment_identifier       = "${local.environment_identifier}"
  internal_domain              = "${local.internal_domain}"
  lb_account_id                = "${local.lb_account_id}"
  region                       = "${local.region}"
  remote_state_bucket_name     = "${local.remote_state_bucket_name}"
  role_arn                     = "${local.role_arn}"
  private_zone_id              = "${local.private_zone_id}"
  s3_lb_policy_file            = "${local.s3_lb_policy_file}"
  short_environment_identifier = "${local.short_environment_identifier}"
  tags                         = "${local.tags}"
  vpc_id                       = "${local.vpc_id}"
}

####################################################
# Self Signed CA
####################################################
module "self_signed_ca" {
  source                               = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=issue-62//projects//alfresco//self-signed//ca"
  is_ca_certificate                    = true
  internal_domain                      = "${local.internal_domain}"
  region                               = "${local.region}"
  tags                                 = "${local.tags}"
  common_name                          = "${local.common_name}"
  self_signed_ca_algorithm             = "${var.self_signed_ca_algorithm}"
  self_signed_ca_rsa_bits              = "${var.self_signed_ca_rsa_bits}"
  self_signed_ca_algorithm             = "${var.self_signed_ca_algorithm}"
  self_signed_ca_validity_period_hours = "${var.self_signed_ca_validity_period_hours}"
  self_signed_ca_early_renewal_hours   = "${var.self_signed_ca_early_renewal_hours}"
  alfresco_app_name                    = "${local.alfresco_app_name}"
  environment_identifier               = "${local.environment_identifier}"
}

####################################################
# Self Signed Cert
####################################################
module "self_signed_cert" {
  source                                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=issue-62//projects//alfresco//self-signed//server"
  alfresco_app_name                        = "${local.alfresco_app_name}"
  ca_cert_pem                              = "${module.self_signed_ca.self_signed_ca_cert_pem}"
  ca_private_key_pem                       = "${module.self_signed_ca.self_signed_ca_private_key}"
  common_name                              = "${local.common_name}"
  environment_identifier                   = "${local.environment_identifier}"
  internal_domain                          = "${local.internal_domain}"
  region                                   = "${local.region}"
  self_signed_server_algorithm             = "${var.self_signed_server_algorithm}"
  self_signed_server_validity_period_hours = "${var.self_signed_server_validity_period_hours}"
  self_signed_server_rsa_bits              = "${var.self_signed_server_rsa_bits}"
  self_signed_server_early_renewal_hours   = "${var.self_signed_server_early_renewal_hours}"
  tags                                     = "${local.tags}"

  depends_on = [
    "${module.self_signed_ca.self_signed_ca_cert_pem}",
    "${module.self_signed_ca.self_signed_ca_private_key}",
  ]
}

####################################################
# Security Groups - Application Specific
####################################################
module "security_groups" {
  source                  = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=issue-62//projects//alfresco//security-groups"
  alfresco_app_name       = "${local.alfresco_app_name}"
  allowed_cidr_block      = ["${local.cidr_block}"]
  common_name             = "${local.common_name}"
  environment_identifier  = "${local.environment_identifier}"
  region                  = "${local.region}"
  tags                    = "${local.tags}"
  vpc_id                  = "${local.vpc_id}"
  public_cidr_block       = ["${local.public_cidr_block}"]
  private_cidr_block      = ["${local.private_cidr_block}"]
  db_cidr_block           = ["${local.db_cidr_block}"]
  alb_http_port           = "80"
  alb_https_port          = "443"
  alb_backend_port        = "8080"
  alfresco_ftp_port       = "21"
  alfresco_smb_port_start = "137"
  alfresco_smb_port_end   = "139"
  alfresco_smb_port       = "445"
  alfresco_arcp_port      = "7070"
  alfresco_apache_jserv   = "8009"
}

####################################################
# S3 bucket - Application Specific
####################################################
module "s3bucket" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=issue-62//projects//alfresco//s3bucket"
  alfresco_app_name        = "${local.alfresco_app_name}"
  environment_identifier   = "${local.environment_identifier}"
  tags                     = "${local.tags}"
  s3cloudtrail_policy_file = "${file("./policies/s3bucket/s3_cloudtrail_policy.json")}"
}

####################################################
# IAM - Application Specific
####################################################
module "iam" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=issue-62//projects//alfresco//iam"
  alfresco_app_name        = "${local.alfresco_app_name}"
  environment_identifier   = "${local.environment_identifier}"
  tags                     = "${local.tags}"
  ec2_role_policy_file     = "${file("./policies/ec2_role_policy.json")}"
  ec2_policy_file          = "ec2_policy.json"
  ec2_internal_policy_file = "${file("policies/ec2_internal_policy.json")}"
  aws_ecr_arn              = "${local.aws_ecr_arn}"
  remote_iam_role          = "${local.remote_iam_role}"
  remote_config_bucket     = "${local.remote_config_bucket}"
  storage_s3bucket         = "${module.s3bucket.s3bucket}"
  s3-config-bucket         = "${module.common.common_s3-config-bucket}"

  depends_on = [
    "${module.s3bucket.s3bucket}",
    "${module.s3bucket.s3bucket-logs}",
    "${module.s3bucket.s3bucket_kms_arn}",
    "${module.s3bucket.s3bucket_kms_id}",
    "${module.s3bucket.s3bucket_cloudtrail_arn}",
    "${module.s3bucket.s3bucket_cloudtrail_id}",
  ]
}

####################################################
# RDS - Application Specific
####################################################
module "rds" {
  source                    = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=issue-62//projects//alfresco//rds"
  alfresco_app_name         = "${local.alfresco_app_name}"
  environment_identifier    = "${local.environment_identifier}"
  tags                      = "${local.tags}"
  subnet_ids                = "${local.db_subnet_ids}"
  create_db_subnet_group    = true
  create_db_parameter_group = true
  create_db_option_group    = true
  create_db_instance        = true
  parameters                = []
  family                    = "postgres9.6"
  engine                    = "postgres"
  major_engine_version      = "9.6"
  engine_version            = "9.6.6"
  port                      = "5432"
  storage_encrypted         = true
  maintenance_window        = "Mon:00:00-Mon:03:00"
  backup_window             = "03:00-06:00"
  multi_az                  = true
  environment               = "${local.environment}"
  zone_id                   = "${local.private_zone_id}"
  internal_domain           = "${local.internal_domain}"
  security_group_ids        = ["${module.security_groups.security_groups_sg_rds_id}"]
  rds_allocated_storage     = "${var.rds_allocated_storage}"
  rds_instance_class        = "${var.rds_instance_class}"
  rds_monitoring_interval   = "30"

  depends_on = [
    "${module.security_groups.security_groups_sg_rds_id}",
  ]
}

####################################################
# ASG - Application Specific
####################################################
module "asg" {
  source                       = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=issue-62//projects//alfresco//asg"
  alfresco_app_name            = "${local.alfresco_app_name}"
  environment_identifier       = "${local.environment_identifier}"
  tags                         = "${local.tags}"
  private_subnet_ids           = "${local.private_subnet_map}"
  short_environment_identifier = "${local.short_environment_identifier}"
  instance_profile             = "${module.iam.iam_policy_int_app_instance_profile_name}"
  access_logs_bucket           = "${module.common.common_s3_lb_logs_bucket}"
  ssh_deployer_key             = "${module.common.common_ssh_deployer_key}"
  bucket_kms_key_id            = "${module.s3bucket.s3bucket_kms_id}"
  alfresco_s3bucket            = "${module.s3bucket.s3bucket}"
  lb_security_groups           = ["${module.security_groups.security_groups_sg_internal_lb_id}"]
  internal                     = true
  az_asg_desired               = "${var.az_asg_desired}"
  az_asg_min                   = "${var.az_asg_min}"
  az_asg_max                   = "${var.az_asg_max}"
  cloudwatch_log_retention     = "${var.cloudwatch_log_retention}"
  zone_id                      = "${local.private_zone_id}"
  internal_domain              = "${local.internal_domain}"
  db_name                      = "${module.rds.rds_db_instance_database_name}"
  db_username                  = "${module.rds.rds_db_instance_username}"
  db_host                      = "${module.rds.rds_db_instance_endpoint_cname}"
  environment                  = "${local.environment}"
  region                       = "${local.region}"
  ami_id                       = "${data.aws_ami.amazon_ami.id}"
  account_id                   = "${module.common.common_account_id}"
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
  user_data                   = "user_data/user_data.sh"
  volume_size                 = "20"
  ebs_device_name             = "/dev/xvdb"
  ebs_volume_type             = "standard"
  ebs_volume_size             = "512"
  ebs_encrypted               = "true"
  instance_type               = "t2.large"
  associate_public_ip_address = false
  cache_home                  = "/srv/cache"

  instance_security_groups = [
    "${module.security_groups.security_groups_sg_internal_instance_id}",
    "${module.common.common_sg_outbound_id}",
    "${local.monitoring_server_client_sg_id}",
    "${local.monitoring_server_client_sg_id}",
  ]

  depends_on = [
    "${module.security_groups.security_groups_sg_internal_instance_id}",
    "${module.common.common_sg_outbound_id}",
    "${module.iam.iam_policy_int_app_instance_profile_name}",
    "${module.s3bucket.s3bucket}",
    "${module.s3bucket.s3bucket-logs}",
    "${module.s3bucket.s3bucket_kms_arn}",
    "${module.s3bucket.s3bucket_kms_id}",
    "${module.self_signed_ca.self_signed_ca_cert_pem}",
    "${module.self_signed_ca.self_signed_ca_private_key}",
  ]
}

####################################################
# Route53 - Public DNS entries
####################################################
# RDS
resource "aws_route53_record" "rds" {
  name    = "${local.alfresco_app_name}-db.${local.external_domain}"
  type    = "CNAME"
  zone_id = "${local.public_zone_id}"
  ttl     = 300
  records = ["${module.rds.rds_db_instance_endpoint}"]
}
