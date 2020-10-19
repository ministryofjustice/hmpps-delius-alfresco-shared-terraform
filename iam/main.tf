terraform {
  # The configuration for this backend will be filled in by Terragrunt
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {
  }
}

####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################
#-------------------------------------------------------------
### Getting the common details
#-------------------------------------------------------------
data "terraform_remote_state" "common" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/common/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the S3bucket details
#-------------------------------------------------------------
data "terraform_remote_state" "s3bucket" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/s3buckets/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the artefacts details
#-------------------------------------------------------------
data "terraform_remote_state" "artefacts" {
  backend = "s3"

  config = {
    bucket   = var.eng_remote_state_bucket_name
    key      = "s3bucket-artefacts/terraform.tfstate"
    region   = var.region
    role_arn = var.eng_role_arn
  }
}

#-------------------------------------------------------------
### Getting the eng-prod bucket
#-------------------------------------------------------------
data "terraform_remote_state" "prod_artefacts" {
  backend = "s3"

  config = {
    bucket   = var.oracle_db_operation["eng_remote_state_bucket_name"]
    key      = "s3bucket-artefacts/terraform.tfstate"
    region   = var.region
    role_arn = var.oracle_db_operation["eng_role_arn"]
  }
}

#-------------------------------------------------------------
## Getting the rds db password
#-------------------------------------------------------------
data "aws_ssm_parameter" "db_user" {
  name = "${local.ssm_path}/alfresco/alfresco/rds_user"
}

data "aws_ssm_parameter" "db_password" {
  name = "${local.ssm_path}/alfresco/alfresco/rds_password"
}

data "aws_ssm_parameter" "spg_mq_user" {
  name = "${local.ssm_path}/weblogic/spg-domain/remote_broker_username"
}

data "aws_ssm_parameter" "spg_mq_password" {
  name = "${local.ssm_path}/weblogic/spg-domain/remote_broker_password"
}

####################################################
# Locals
####################################################

locals {
  region                    = var.region
  alfresco_app_name         = data.terraform_remote_state.common.outputs.alfresco_app_name
  common_name               = data.terraform_remote_state.common.outputs.common_name
  tags                      = data.terraform_remote_state.common.outputs.common_tags
  alfresco-storage_s3bucket = data.terraform_remote_state.s3bucket.outputs.s3bucket
  config-bucket             = data.terraform_remote_state.common.outputs.common_s3-config-bucket
  remote_config_bucket      = data.terraform_remote_state.common.outputs.remote_config_bucket
  remote_iam_role           = data.terraform_remote_state.common.outputs.remote_iam_role
  alfresco_kms_arn          = data.terraform_remote_state.s3bucket.outputs.s3bucket_kms_arn
  vpc_cidr                  = data.terraform_remote_state.common.outputs.vpc_cidr_block
  alf_backups_bucket_arn    = data.terraform_remote_state.s3bucket.outputs.alf_backups_bucket_arn
  elk_backups_bucket_arn    = data.terraform_remote_state.s3bucket.outputs.elk_backups_bucket_arn
  artefacts-s3bucket-arn    = var.is_production == true ? data.terraform_remote_state.prod_artefacts.outputs.s3bucket_artefacts_iam_arn : data.terraform_remote_state.artefacts.outputs.s3bucket_artefacts_iam_arn
  ssm_path                  = data.terraform_remote_state.common.outputs.credentials_ssm_path
}

####################################################
# IAM - Application Specific
####################################################
module "iam" {
  source                   = "../modules/iam"
  common_name              = local.common_name
  tags                     = local.tags
  ec2_policy_file          = "ec2_policy.json"
  ec2_internal_policy_file = file("../policies/ec2_internal_policy.json")
  remote_iam_role          = local.remote_iam_role
  remote_config_bucket     = local.remote_config_bucket
  storage_s3bucket         = local.alfresco-storage_s3bucket
  s3-config-bucket         = local.config-bucket
  s3bucket_kms_arn         = local.alfresco_kms_arn
  asg_ssm_arns_map = {
    db_user                = data.aws_ssm_parameter.db_user.arn
    db_password            = data.aws_ssm_parameter.db_password.arn
    remote_broker_username = data.aws_ssm_parameter.spg_mq_user.arn
    remote_broker_password = data.aws_ssm_parameter.spg_mq_password.arn
  }
}

