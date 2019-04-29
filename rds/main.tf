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
}

####################################################
# RDS - Application Specific
####################################################
module "rds" {
  source                    = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//projects//alfresco//rds"
  alfresco_app_name         = "${local.alfresco_app_name}"
  environment_identifier    = "${local.environment_identifier}"
  common_name               = "${local.common_name}"
  tags                      = "${local.tags}"
  subnet_ids                = "${local.db_subnet_ids}"
  create_db_subnet_group    = true
  create_db_parameter_group = true
  create_db_option_group    = true
  create_db_instance        = true
  parameters                = ["${var.db_parameters}"]
  family                    = "postgres9.4"
  engine                    = "postgres"
  major_engine_version      = "9.4"
  engine_version            = "9.4.20"
  port                      = "5432"
  storage_encrypted         = true
  maintenance_window        = "Mon:00:00-Mon:03:00"
  backup_window             = "03:00-06:00"
  multi_az                  = true
  environment               = "${replace("${local.environment}", "-", "")}"
  private_zone_id           = "${local.private_zone_id}"
  internal_domain           = "${local.internal_domain}"
  security_group_ids        = ["${local.security_group_ids}"]
  rds_allocated_storage     = "${var.rds_allocated_storage}"
  rds_instance_class        = "${var.rds_instance_class}"
  rds_monitoring_interval   = "30"
}
