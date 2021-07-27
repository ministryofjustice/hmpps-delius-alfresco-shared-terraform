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
### Getting the current vpc
#-------------------------------------------------------------
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "vpc/terraform.tfstate"
    region = var.region
  }
}

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
### Getting the sg details
#-------------------------------------------------------------
data "terraform_remote_state" "security-groups" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "security-groups/terraform.tfstate"
    region = var.region
  }
}

####################################################
# Locals
####################################################

locals {
  vpc_id                 = data.terraform_remote_state.common.outputs.vpc_id
  cidr_block             = data.terraform_remote_state.common.outputs.vpc_cidr_block
  common_name            = data.terraform_remote_state.common.outputs.common_name
  region                 = data.terraform_remote_state.common.outputs.region
  alfresco_app_name      = data.terraform_remote_state.common.outputs.alfresco_app_name
  environment_identifier = data.terraform_remote_state.common.outputs.environment_identifier
  environment            = data.terraform_remote_state.common.outputs.environment
  tags                   = data.terraform_remote_state.common.outputs.common_tags
  public_cidr_block      = [data.terraform_remote_state.common.outputs.db_cidr_block]
  private_cidr_block     = [data.terraform_remote_state.common.outputs.private_cidr_block]
  db_cidr_block          = [data.terraform_remote_state.common.outputs.db_cidr_block]
  vpn_source_cidrs       = data.terraform_remote_state.common.outputs.vpn_info["source_cidrs"]

  sg_map_ids = {
    internal_inst_sg_id = data.terraform_remote_state.security-groups.outputs.sg_alfresco_api_in
    elasticache_sg_id   = data.terraform_remote_state.security-groups.outputs.sg_alfresco_elasticache_in
    db_sg_id            = data.terraform_remote_state.security-groups.outputs.sg_alfresco_db_in
    external_lb_sg_id   = data.terraform_remote_state.security-groups.outputs.sg_alfresco_external_lb_in
    internal_lb_sg_id   = data.terraform_remote_state.security-groups.outputs.sg_alfresco_internal_lb_in
    external_inst_sg_id = data.terraform_remote_state.security-groups.outputs.sg_alfresco_nginx_in
    bastion_in_sg_id    = data.terraform_remote_state.security-groups.outputs.sg_ssh_bastion_in_id
    efs_sg_id           = data.terraform_remote_state.security-groups.outputs.sg_alfresco_efs_in
    mon_jenkins         = data.terraform_remote_state.security-groups.outputs.sg_mon_jenkins
    monitoring_client   = data.terraform_remote_state.security-groups.outputs.sg_monitoring_client
  }

  allowed_cidr_block = [
    distinct(concat(var.user_access_cidr_blocks, var.alfresco_access_cidr_blocks)),
    data.terraform_remote_state.common.outputs.nat_gateway_ips,
  ]
}

####################################################
# Security Groups - Application Specific
####################################################
module "security_groups" {
  source                  = "../modules/security-groups"
  alfresco_app_name       = local.alfresco_app_name
  allowed_cidr_block      = flatten(local.allowed_cidr_block)
  common_name             = local.common_name
  environment_identifier  = local.environment_identifier
  region                  = local.region
  tags                    = local.tags
  vpc_id                  = local.vpc_id
  public_cidr_block       = flatten(local.public_cidr_block)
  private_cidr_block      = flatten(local.private_cidr_block)
  db_cidr_block           = flatten(local.db_cidr_block)
  sg_map_ids              = local.sg_map_ids
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

#-------------------------------------------------------------
### efs sg
#-------------------------------------------------------------
resource "aws_security_group_rule" "internal_inst_sg_ingress_self" {
  security_group_id = local.sg_map_ids["efs_sg_id"]
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}

resource "aws_security_group_rule" "internal_inst_sg_egress_self" {
  security_group_id = local.sg_map_ids["efs_sg_id"]
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}

# MQ
resource "aws_security_group_rule" "internal_inst_sg_egress_mq" {
  security_group_id = local.sg_map_ids["internal_inst_sg_id"]
  type              = "egress"
  from_port         = "61616"
  to_port           = "61617"
  protocol          = "tcp"
  cidr_blocks       = [local.cidr_block]

  description = "${local.common_name}-mq-sg"
}

# tunnelling
resource "aws_security_group_rule" "bastion_tunnel_alf" {
  security_group_id = local.sg_map_ids["internal_inst_sg_id"]
  type              = "ingress"
  from_port         = "8080"
  to_port           = "8080"
  protocol          = "tcp"
  cidr_blocks = flatten(values(
    data.terraform_remote_state.vpc.outputs.bastion_vpc_public_cidr,
  ))
  description = "bastion tunnelling"
}

