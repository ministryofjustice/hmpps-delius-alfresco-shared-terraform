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
  vpc_id                          = "${data.terraform_remote_state.common.vpc_id}"
  cidr_block                      = "${data.terraform_remote_state.common.vpc_cidr_block}"
  allowed_cidr_block              = ["${data.terraform_remote_state.common.vpc_cidr_block}"]
  internal_domain                 = "${data.terraform_remote_state.common.internal_domain}"
  private_zone_id                 = "${data.terraform_remote_state.common.private_zone_id}"
  external_domain                 = "${data.terraform_remote_state.common.external_domain}"
  public_zone_id                  = "${data.terraform_remote_state.common.public_zone_id}"
  common_name                     = "${data.terraform_remote_state.common.common_name}-debug-db"
  environment_identifier          = "${data.terraform_remote_state.common.environment_identifier}"
  region                          = "${var.region}"
  alfresco_app_name               = "alfresco"
  environment                     = "${data.terraform_remote_state.common.environment}"
  tags                            = "${data.terraform_remote_state.common.common_tags}"
  public_cidr_block               = ["${data.terraform_remote_state.common.db_cidr_block}"]
  private_cidr_block              = ["${data.terraform_remote_state.common.private_cidr_block}"]
  db_cidr_block                   = ["${data.terraform_remote_state.common.db_cidr_block}"]
  private_subnet_map              = "${data.terraform_remote_state.common.private_subnet_map}"
  db_subnet_ids                   = ["${data.terraform_remote_state.common.db_subnet_ids}"]
  security_group_ids              = ["${data.terraform_remote_state.security-groups.security_groups_sg_rds_id}"]
  credentials_ssm_path            = "${data.terraform_remote_state.common.credentials_ssm_path}"
  logs_kms_arn                    = "${data.terraform_remote_state.common.kms_arn}"
  dns_name                        = "debug_alf_db"
  db_name                         = "${local.alfresco_app_name}"
  db_user_name                    = "${data.aws_ssm_parameter.db_user.value}"
  db_password                     = "${data.aws_ssm_parameter.db_password.value}"
  family                          = "postgres9.6"
  engine                          = "postgres"
  major_engine_version            = "9.6"
  replica_engine_version          = "9.6.9"
  master_engine_version           = "9.6.9"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  port                            = 5432
}

####################################################
# RDS - Application Specific
####################################################

#-------------------------------------------------------------
## Getting the rds db password
#-------------------------------------------------------------
data "aws_ssm_parameter" "db_user" {
  name = "${local.credentials_ssm_path}/alfresco/alfresco/rds_user"
}

data "aws_ssm_parameter" "db_password" {
  name = "${local.credentials_ssm_path}/alfresco/alfresco/rds_password"
}

############################################
# CREATE PARAMETER GROUP
############################################

module "parameter_group" {
  source = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//rds//db_parameter_group"

  create      = true
  identifier  = "${local.common_name}"
  name_prefix = "${local.common_name}-"
  family      = "${local.family}"

  parameters = ["${var.alf_db_parameters}"]

  tags = "${local.tags}"
}


# ENBALE FOR RESTORE AND ATTACH TO PRIMARY NODE
module "restore_parameter_group" {
  source = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//rds//db_parameter_group"

  create      = true
  identifier  = "${local.common_name}-restore"
  name_prefix = "${local.common_name}-restore-"
  family      = "${local.family}"

  parameters = [
    {
      name         = "maintenance_work_mem"
      value        = 1048576
      apply_method = "pending-reboot"
    },
    {
      name         = "max_wal_size"
      value        = 256
      apply_method = "pending-reboot"
    },
    {
      name         = "checkpoint_timeout"
      value        = 1800
      apply_method = "pending-reboot"
    },
    {
      name         = "synchronous_commit"
      value        = "Off"
      apply_method = "pending-reboot"
    },
    {
      name         = "wal_buffers"
      value        = 8192
      apply_method = "pending-reboot"
    },
    {
      name         = "autovacuum"
      value        = "Off"
      apply_method = "pending-reboot"
    }
  ]

  tags = "${local.tags}"
}
