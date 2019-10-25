####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

#-------------------------------------------------------------
## Getting the rds db password
#-------------------------------------------------------------
data "aws_ssm_parameter" "db_user" {
  name = "${var.credentials_ssm_path}/alfresco/alfresco/rds_user"
}

data "aws_ssm_parameter" "db_password" {
  name = "${var.credentials_ssm_path}/alfresco/alfresco/rds_password"
}

locals {
  common_name         = "${var.common_name}-rds"
  replica_common_name = "${var.common_name}-rpl"
  dns_name            = "${var.alfresco_app_name}-db"
  db_name             = "${var.alfresco_app_name}${var.environment}"
  db_user_name        = "${data.aws_ssm_parameter.db_user.value}"
  db_password         = "${data.aws_ssm_parameter.db_password.value}"
  tags                = "${var.tags}"
}

############################################
# KMS KEY GENERATION - FOR ENCRYPTION
############################################

module "kms_key" {
  source              = "../kms"
  kms_key_name        = "${local.common_name}"
  tags                = "${local.tags}"
  kms_policy_template = "policies/rds.kms.json"
}

############################################
# CREATE IAM POLICIES
############################################

#-------------------------------------------------------------
### IAM ROLE FOR RDS
#-------------------------------------------------------------

module "rds_monitoring_role" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//iam//role"
  rolename   = "${local.common_name}-monitoring"
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
  create      = "${var.create_db_subnet_group}"
  identifier  = "${local.common_name}"
  name_prefix = "${local.common_name}-"
  subnet_ids  = ["${var.subnet_ids}"]
  tags        = "${local.tags}"
}

############################################
# CREATE PARAMETER GROUP
############################################
# module "db_parameter_group" {
#   source = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//rds//db_parameter_group"

#   create      = "${var.create_db_parameter_group}"
#   identifier  = "${local.common_name}"
#   name_prefix = "${local.common_name}-"
#   family      = "${var.family}"

#   parameters = ["${var.parameters_restore}"]

#   tags = "${local.tags}"
# }

module "parameter_group" {
  source = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//rds//db_parameter_group"

  create      = "${var.create_db_parameter_group}"
  identifier  = "${local.common_name}-live"
  name_prefix = "${local.common_name}-live-"
  family      = "${var.family}"

  parameters = ["${var.parameters}"]

  tags = "${local.tags}"
}

############################################
# CREATE DB OPTIONS
############################################
module "db_option_group" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//rds//db_option_group"
  create                   = "${var.create_db_option_group}"
  identifier               = "${local.common_name}"
  name_prefix              = "${local.common_name}-"
  option_group_description = "${local.common_name} options group"
  engine_name              = "${var.engine}"
  major_engine_version     = "${var.major_engine_version}"

  options = ["${var.options}"]

  tags = "${local.tags}"
}
