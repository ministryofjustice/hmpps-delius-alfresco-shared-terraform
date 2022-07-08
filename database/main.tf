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
### Getting the security groups details
#-------------------------------------------------------------
data "terraform_remote_state" "security-groups" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/security-groups/terraform.tfstate"
    region = var.region
  }
}

####################################################
# Locals
####################################################

locals {
  alf_database_config             = merge(var.alf_rds_props, var.alf_database_map)
  vpc_id                          = data.terraform_remote_state.common.outputs.vpc_id
  cidr_block                      = data.terraform_remote_state.common.outputs.vpc_cidr_block
  allowed_cidr_block              = [data.terraform_remote_state.common.outputs.vpc_cidr_block]
  internal_domain                 = data.terraform_remote_state.common.outputs.internal_domain
  private_zone_id                 = data.terraform_remote_state.common.outputs.private_zone_id
  external_domain                 = data.terraform_remote_state.common.outputs.external_domain
  public_zone_id                  = data.terraform_remote_state.common.outputs.public_zone_id
  common_name                     = "${data.terraform_remote_state.common.outputs.common_name}-database"
  environment_identifier          = data.terraform_remote_state.common.outputs.environment_identifier
  region                          = var.region
  alfresco_app_name               = "alfresco"
  environment                     = data.terraform_remote_state.common.outputs.environment
  tags                            = data.terraform_remote_state.common.outputs.common_tags
  public_cidr_block               = [data.terraform_remote_state.common.outputs.db_cidr_block]
  private_cidr_block              = [data.terraform_remote_state.common.outputs.private_cidr_block]
  db_cidr_block                   = [data.terraform_remote_state.common.outputs.db_cidr_block]
  private_subnet_map              = data.terraform_remote_state.common.outputs.private_subnet_map
  db_subnet_ids                   = [data.terraform_remote_state.common.outputs.db_subnet_ids]
  security_group_ids              = [data.terraform_remote_state.security-groups.outputs.security_groups_sg_rds_id]
  credentials_ssm_path            = data.terraform_remote_state.common.outputs.credentials_ssm_path
  logs_kms_arn                    = data.terraform_remote_state.common.outputs.kms_arn
  dns_name                        = "alf_db_host"
  db_name                         = local.alfresco_app_name
  db_user_name                    = data.aws_ssm_parameter.db_user.value
  db_password                     = data.aws_ssm_parameter.db_password.value
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
# KMS KEY GENERATION - FOR ENCRYPTION
############################################

module "kms_key" {
  source              = "../modules/kms"
  kms_key_name        = local.common_name
  tags                = local.tags
  kms_policy_template = var.environment_type == "prod" ? "policies/rds-kms-cross-account.json" : "policies/rds.kms.json"
}

############################################
# CREATE IAM POLICIES
############################################

#-------------------------------------------------------------
### IAM ROLE FOR RDS
#-------------------------------------------------------------

module "rds_monitoring_role" {
  source     = "../modules/iam/role"
  rolename   = local.common_name
  policyfile = "rds_monitoring.json"
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  role       = module.rds_monitoring_role.iamrole_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

############################################
# CREATE DB SUBNET GROUP
############################################
module "db_subnet_group" {
  source      = "../modules/rds/db_subnet_group"
  create      = true
  identifier  = local.common_name
  name_prefix = "${local.common_name}-"
  subnet_ids  = flatten(local.db_subnet_ids)
  tags        = local.tags
}

# Commenting this parameter group because alfresco-database instance uses the default parameter now, not these custom ones.
# After this terraform has been applied (which will remove the parameter group), this code block can be removed.
############################################
# CREATE PARAMETER GROUP
############################################
# module "parameter_group" {
#   source = "../modules/rds/db_parameter_group"

#   create      = true
#   identifier  = local.common_name
#   name_prefix = "${local.common_name}-"
#   family      = local.family

#   parameters = flatten(var.alf_db_parameters)

#   tags = local.tags
# }

# # ENBALE FOR RESTORE AND ATTACH TO PRIMARY NODE
# # module "restore_parameter_group" {
# #   source = "../modules/rds/db_parameter_group"

# #   create      = true
# #   identifier  = "${local.common_name}-restore"
# #   name_prefix = "${local.common_name}-restore-"
# #   family      = "${local.family}"

# #   parameters = [
# #     {
# #       name         = "maintenance_work_mem"
# #       value        = 1048576
# #       apply_method = "pending-reboot"
# #     },
# #     {
# #       name         = "max_wal_size"
# #       value        = 256
# #       apply_method = "pending-reboot"
# #     },
# #     {
# #       name         = "checkpoint_timeout"
# #       value        = 1800
# #       apply_method = "pending-reboot"
# #     },
# #     {
# #       name         = "synchronous_commit"
# #       value        = "Off"
# #       apply_method = "pending-reboot"
# #     },
# #     {
# #       name         = "wal_buffers"
# #       value        = 8192
# #       apply_method = "pending-reboot"
# #     },
# #     {
# #       name         = "autovacuum"
# #       value        = "Off"
# #       apply_method = "pending-reboot"
# #     }
# #   ]

# #   tags = "${local.tags}"
# # }

# Unlike the commented-out block above relating to parameter groups (see note above), there are still numerous rds snapshots referencing
#   the option group. So this can only be commented out when the snapshots are removed
############################################
# CREATE DB OPTIONS
############################################
module "db_option_group" {
  source                   = "../modules/rds/db_option_group"
  create                   = true
  identifier               = local.common_name
  name_prefix              = "${local.common_name}-"
  option_group_description = "${local.common_name} options group"
  engine_name              = local.engine
  major_engine_version     = local.major_engine_version

  options = flatten(var.alf_db_options)

  tags = local.tags
}

