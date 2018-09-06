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
### Getting the current vpc
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
### Getting the common details
#-------------------------------------------------------------
data "terraform_remote_state" "common" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "${var.alfresco_app_name}/common/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the security groups
#-------------------------------------------------------------
data "terraform_remote_state" "security_groups" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "${var.alfresco_app_name}/service-alfresco/security-groups/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the rds db password
#-------------------------------------------------------------
# data "aws_ssm_parameter" "db_password" {
#   name = "/${var.environment}/${var.alfresco_app_name}/rds/db_instance/db_password"
# }

locals {
  common_name = "${var.environment_identifier}-${var.alfresco_app_name}-rds"
  dns_name    = "${var.alfresco_app_name}-db"
  db_identity = "${var.alfresco_app_name}${var.environment}"
  db_password =  "123456sdfghjkk" #"${data.aws_ssm_parameter.db_password.value}"
  tags        = "${data.terraform_remote_state.common.common_tags}"
}

############################################
# KMS KEY GENERATION - FOR ENCRYPTION
############################################

module "kms_key" {
  source       = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//kms"
  kms_key_name = "${local.common_name}"
  tags         = "${local.tags}"
}

############################################
# CREATE IAM POLICIES
############################################

#-------------------------------------------------------------
### IAM ROLE FOR RDS
#-------------------------------------------------------------

module "rds_monitoring_role" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//iam//role"
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
  source      = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//rds//db_subnet_group"
  create      = "${var.create_db_subnet_group}"
  identifier  = "${local.common_name}"
  name_prefix = "${local.common_name}-"

  subnet_ids = ["${data.terraform_remote_state.vpc.vpc_db-subnet-az1}",
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az2}",
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az3}",
  ]

  tags = "${local.tags}"
}

############################################
# CREATE PARAMETER GROUP
############################################
module "db_parameter_group" {
  source = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//rds//db_parameter_group"

  create      = "${var.create_db_parameter_group}"
  identifier  = "${local.common_name}"
  name_prefix = "${local.common_name}-"
  family      = "${var.family}"

  parameters = ["${var.parameters}"]

  tags = "${local.tags}"
}

############################################
# CREATE DB OPTIONS
############################################
module "db_option_group" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//rds//db_option_group"
  create                   = "${var.create_db_option_group}"
  identifier               = "${local.common_name}"
  name_prefix              = "${local.common_name}-"
  option_group_description = "${local.common_name} options group"
  engine_name              = "${var.engine}"
  major_engine_version     = "${var.major_engine_version}"

  options = ["${var.options}"]

  tags = "${local.tags}"
}

############################################
# CREATE DB INSTANCE
############################################

module "db_instance" {
  source = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//rds//db_instance"

  create            = "${var.create_db_instance}"
  identifier        = "${local.common_name}"
  engine            = "${var.engine}"
  engine_version    = "${var.engine_version}"
  instance_class    = "${var.rds_instance_class}"
  allocated_storage = "${var.rds_allocated_storage}"
  storage_type      = "${var.storage_type}"
  storage_encrypted = "${var.storage_encrypted}"
  kms_key_id        = "${module.kms_key.kms_arn}"
  license_model     = "${var.license_model}"

  name                                = "${local.db_identity}"
  username                            = "${local.db_identity}"
  password                            = "${local.db_password}"
  port                                = "${var.port}"
  iam_database_authentication_enabled = "${var.iam_database_authentication_enabled}"

  replicate_source_db = "${var.replicate_source_db}"

  snapshot_identifier = "${var.snapshot_identifier}"

  vpc_security_group_ids = [
    "${data.terraform_remote_state.security_groups.service_alfresco_security_groups_sg_rds_id}",
  ]

  db_subnet_group_name = "${module.db_subnet_group.db_subnet_group_id}"
  parameter_group_name = "${module.db_parameter_group.db_parameter_group_id}"
  option_group_name    = "${module.db_option_group.db_option_group_id}"

  multi_az            = "${var.multi_az}"
  iops                = "${var.iops}"
  publicly_accessible = "${var.publicly_accessible}"

  allow_major_version_upgrade = "${var.allow_major_version_upgrade}"
  auto_minor_version_upgrade  = "${var.auto_minor_version_upgrade}"
  apply_immediately           = "${var.apply_immediately}"
  maintenance_window          = "${var.maintenance_window}"
  skip_final_snapshot         = "${var.skip_final_snapshot}"
  copy_tags_to_snapshot       = "${var.copy_tags_to_snapshot}"
  final_snapshot_identifier   = "${local.common_name}-final-snapshot"

  backup_retention_period = "${var.rds_backup_retention_period}"
  backup_window           = "${var.backup_window}"

  monitoring_interval  = "${var.rds_monitoring_interval}"
  monitoring_role_arn  = "${module.rds_monitoring_role.iamrole_arn}"
  monitoring_role_name = "${module.rds_monitoring_role.iamrole_name}"

  timezone           = "${var.timezone}"
  character_set_name = "${var.character_set_name}"

  tags = "${local.tags}"
}

###############################################
# Create route53 entry for rds
###############################################

resource "aws_route53_record" "rds_dns_entry" {
  name    = "${local.dns_name}.${data.terraform_remote_state.common.common_private_zone_name}"
  type    = "CNAME"
  zone_id = "${data.terraform_remote_state.common.common_private_zone_id}"
  ttl     = 300
  records = ["${module.db_instance.db_instance_address}"]
}
