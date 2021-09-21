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
### Getting the s3 details
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
### Getting the IAM details
#-------------------------------------------------------------
data "terraform_remote_state" "iam" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/iam/terraform.tfstate"
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

#-------------------------------------------------------------
### Getting the network security groups details
#-------------------------------------------------------------
data "terraform_remote_state" "network-security-groups" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "security-groups/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting ACM Cert
#-------------------------------------------------------------
data "aws_acm_certificate" "cert" {
  domain      = "*.${data.terraform_remote_state.common.outputs.external_domain}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

####################################################
# Locals
####################################################

locals {
  account_id                   = data.terraform_remote_state.common.outputs.common_account_id
  vpc_id                       = data.terraform_remote_state.common.outputs.vpc_id
  vpc_cidr_block               = data.terraform_remote_state.common.outputs.vpc_cidr_block
  internal_domain              = data.terraform_remote_state.common.outputs.internal_domain
  private_zone_id              = data.terraform_remote_state.common.outputs.private_zone_id
  public_zone_id               = data.terraform_remote_state.common.outputs.public_zone_id
  external_domain              = data.terraform_remote_state.common.outputs.external_domain
  environment_identifier       = data.terraform_remote_state.common.outputs.environment_identifier
  application                  = "alf-elk-svc"
  common_name                  = "${data.terraform_remote_state.common.outputs.short_environment_identifier}-${local.application}"
  alf_elk_service_props        = merge(var.alf_elk_service_props, var.alf_elk_service_map)
  domain_name                  = local.alf_elk_service_props["domain_name_type"] == "full" ? local.common_name : local.application
  short_environment_identifier = data.terraform_remote_state.common.outputs.short_environment_identifier
  region                       = var.region
  environment                  = data.terraform_remote_state.common.outputs.environment
  tags                         = data.terraform_remote_state.common.outputs.common_tags
  instance_profile             = data.terraform_remote_state.iam.outputs.iam_instance_es_admin_profile_name
  es_admin_role_name           = data.terraform_remote_state.iam.outputs.iam_instance_es_admin_role_name
  ssh_deployer_key             = data.terraform_remote_state.common.outputs.common_ssh_deployer_key
  s3bucket                     = data.terraform_remote_state.s3bucket.outputs.s3bucket
  bastion_inventory            = var.bastion_inventory
  bastion_cidrs                = data.terraform_remote_state.vpc.outputs.bastion_vpc_public_cidr
  logs_kms_arn                 = data.terraform_remote_state.common.outputs.kms_arn
  config-bucket                = data.terraform_remote_state.common.outputs.common_s3-config-bucket
  certificate_arn              = data.aws_acm_certificate.cert.arn
  public_subnet_ids            = data.terraform_remote_state.common.outputs.public_subnet_ids
  private_subnet_ids           = data.terraform_remote_state.common.outputs.private_subnet_ids
  elk_bucket_name              = data.terraform_remote_state.s3bucket.outputs.elk_backups_bucket_name
  elk_backups_bucket_arn       = data.terraform_remote_state.s3bucket.outputs.elk_backups_bucket_arn
  storage_s3bucket             = data.terraform_remote_state.s3bucket.outputs.s3bucket
  backups_bucket               = data.terraform_remote_state.s3bucket.outputs.alf_backups_bucket_name
  storage_kms_arn              = data.terraform_remote_state.s3bucket.outputs.s3bucket_kms_arn
  kibana_host_fqdn             = "alf6kibana.${local.external_domain}"
  kibana_host_url              = "https://${local.kibana_host_fqdn}"
  access_logs_bucket           = data.terraform_remote_state.common.outputs.common_s3_lb_logs_bucket
  ecs_cluster_name             = data.terraform_remote_state.common.outputs.ecs_cluster["name"]
  service_discovery_domain     = "${local.application}-${local.internal_domain}"
  vpn_source_cidrs             = data.terraform_remote_state.common.outputs.vpn_info["source_cidrs"]

  allowed_cidr_block = [
    var.user_access_cidr_blocks,
    data.terraform_remote_state.common.outputs.nat_gateway_ips
  ]
}

