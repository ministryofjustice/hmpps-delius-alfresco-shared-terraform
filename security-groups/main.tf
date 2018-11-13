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

####################################################
# Locals
####################################################

locals {
  vpc_id                 = "${data.terraform_remote_state.common.vpc_id}"
  cidr_block             = "${data.terraform_remote_state.common.vpc_cidr_block}"
  allowed_cidr_block     = ["${var.allowed_cidr_block}"]
  common_name            = "${data.terraform_remote_state.common.environment_identifier}"
  region                 = "${data.terraform_remote_state.common.region}"
  alfresco_app_name      = "${data.terraform_remote_state.common.alfresco_app_name}"
  environment_identifier = "${data.terraform_remote_state.common.environment_identifier}"
  environment            = "${data.terraform_remote_state.common.environment}"
  tags                   = "${data.terraform_remote_state.common.common_tags}"
  public_cidr_block      = ["${data.terraform_remote_state.common.db_cidr_block}"]
  private_cidr_block     = ["${data.terraform_remote_state.common.private_cidr_block}"]
  db_cidr_block          = ["${data.terraform_remote_state.common.db_cidr_block}"]
  sg_map_ids             = "${data.terraform_remote_state.common.sg_map_ids}"
}

####################################################
# Security Groups - Application Specific
####################################################
module "security_groups" {
  source                  = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=issue-80//projects//alfresco//security-groups"
  alfresco_app_name       = "${local.alfresco_app_name}"
  allowed_cidr_block      = ["${local.allowed_cidr_block}"]
  common_name             = "${local.common_name}"
  environment_identifier  = "${local.environment_identifier}"
  region                  = "${local.region}"
  tags                    = "${local.tags}"
  vpc_id                  = "${local.vpc_id}"
  public_cidr_block       = ["${local.public_cidr_block}"]
  private_cidr_block      = ["${local.private_cidr_block}"]
  db_cidr_block           = ["${local.db_cidr_block}"]
  sg_map_ids              = "${local.sg_map_ids}"
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
