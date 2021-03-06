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
  common_name                     = "tf-alf-solr-gdpr-db"
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
  db_kms_key_arn                  = "${data.terraform_remote_state.rds.kms_key}"
  dns_name                        = "solr_gdpr_db_host"
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

#-------------------------------------------------------------
### Getting the rds details
#-------------------------------------------------------------
data "terraform_remote_state" "rds" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/database/terraform.tfstate"
    region = "${var.region}"
  }
}

############################################
# CREATE IAM POLICIES
############################################

#-------------------------------------------------------------
### IAM ROLE FOR RDS
#-------------------------------------------------------------

module "rds_monitoring_role" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//iam//role"
  rolename   = "${local.common_name}"
  policyfile = "rds_monitoring.json"
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  role       = "${module.rds_monitoring_role.iamrole_name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

############################################
# CREATE DB SUBNET GROUP
############################################
module "db_subnet_group" {
  source      = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//rds//db_subnet_group"
  create      = true
  identifier  = "${local.common_name}"
  name_prefix = "${local.common_name}-"
  subnet_ids  = ["${local.db_subnet_ids}"]
  tags        = "${local.tags}"
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

############################################
# CREATE DB OPTIONS
############################################
module "db_option_group" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//rds//db_option_group"
  create                   = true
  identifier               = "${local.common_name}"
  name_prefix              = "${local.common_name}-"
  option_group_description = "${local.common_name} options group"
  engine_name              = "${local.engine}"
  major_engine_version     = "${local.major_engine_version}"

  options = ["${var.alf_db_options}"]

  tags = "${local.tags}"
}

