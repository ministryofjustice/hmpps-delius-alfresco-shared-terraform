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
data "terraform_remote_state" "security-groups" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/security-groups/terraform.tfstate"
    region = "${var.region}"
  }
}

####################################################
# Locals
####################################################

locals {
  vpc_id                 = "${data.terraform_remote_state.common.vpc_id}"
  cidr_block             = "${data.terraform_remote_state.common.vpc_cidr_block}"
  allowed_cidr_block     = ["${data.terraform_remote_state.common.vpc_cidr_block}"]
  internal_domain        = "${data.terraform_remote_state.common.internal_domain}"
  private_zone_id        = "${data.terraform_remote_state.common.private_zone_id}"
  external_domain        = "${data.terraform_remote_state.common.external_domain}"
  public_zone_id         = "${data.terraform_remote_state.common.public_zone_id}"
  common_name            = "${data.terraform_remote_state.common.common_name}"
  environment_identifier = "${data.terraform_remote_state.common.environment_identifier}"
  region                 = "${var.region}"
  alfresco_app_name      = "${data.terraform_remote_state.common.alfresco_app_name}"
  environment            = "${data.terraform_remote_state.common.environment}"
  tags                   = "${data.terraform_remote_state.common.common_tags}"
  public_cidr_block      = ["${data.terraform_remote_state.common.db_cidr_block}"]
  private_cidr_block     = ["${data.terraform_remote_state.common.private_cidr_block}"]
  db_cidr_block          = ["${data.terraform_remote_state.common.db_cidr_block}"]
  private_subnet_map     = "${data.terraform_remote_state.common.private_subnet_map}"
  db_subnet_ids          = ["${data.terraform_remote_state.common.db_subnet_ids}"]
  security_group_ids     = ["${data.terraform_remote_state.security-groups.security_groups_sg_rds_id}"]
  credentials_ssm_path   = "${data.terraform_remote_state.common.credentials_ssm_path}"
  logs_kms_arn           = "${data.terraform_remote_state.common.kms_arn}"
}

####################################################
# RDS - Application Specific
####################################################
module "rds" {
  source                          = "../modules/rds"
  alfresco_app_name               = "${local.alfresco_app_name}"
  environment_identifier          = "${local.environment_identifier}"
  common_name                     = "${local.common_name}"
  tags                            = "${local.tags}"
  subnet_ids                      = "${local.db_subnet_ids}"
  create_db_subnet_group          = true
  create_db_parameter_group       = true
  create_db_option_group          = true
  create_db_instance              = true
  parameters                      = ["${var.alf_db_parameters}"] # ["${var.alf_rds_migration_parameters}"]
  parameters_restore              = ["${var.alf_rds_migration_parameters}"]
  family                          = "${var.alf_rds_props["family"]}"
  engine                          = "${var.alf_rds_props["engine"]}"
  major_engine_version            = "${var.alf_rds_props["major_engine_version"]}"
  master_engine_version           = "${var.alf_rds_props["master_engine_version"]}"
  replica_engine_version          = "${var.alf_rds_props["replica_engine_version"]}"
  port                            = "5432"
  storage_encrypted               = true
  maintenance_window              = "${var.alf_rds_props["maintenance_window"]}"
  backup_window                   = "${var.alf_rds_props["backup_window"]}"
  multi_az                        = "${var.alf_data_import == "enabled" ? false : true}"
  environment                     = "${replace("${local.environment}", "-", "")}"
  private_zone_id                 = "${local.private_zone_id}"
  internal_domain                 = "${local.internal_domain}"
  security_group_ids              = ["${local.security_group_ids}"]
  rds_allocated_storage           = "${var.alf_rds_props["allocated_storage"]}"
  rds_instance_class              = "${var.alf_rds_props["instance_class"]}"
  iops                            = "${var.alf_rds_props["iops"]}"
  storage_type                    = "${var.alf_rds_props["storage_type"]}"
  rds_backup_retention_period     = "${var.alf_data_import == "enabled" ? 0 : var.alf_rds_props["backup_retention_period"]}"
  rds_monitoring_interval         = "30"
  credentials_ssm_path            = "${local.credentials_ssm_path}"
  data_import                     = "${var.alf_data_import}"
  copy_tags_to_snapshot           = true
  region                          = "${local.region}"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  cloudwatch_log_retention        = "${var.alf_cloudwatch_log_retention}"
  logs_kms_arn                    = "${local.logs_kms_arn}"
}

