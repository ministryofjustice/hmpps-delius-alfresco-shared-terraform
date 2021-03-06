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

####################################################
# Locals
####################################################

locals {
  account_id                   = data.terraform_remote_state.common.outputs.common_account_id
  vpc_id                       = data.terraform_remote_state.common.outputs.vpc_id
  internal_domain              = data.terraform_remote_state.common.outputs.internal_domain
  private_zone_id              = data.terraform_remote_state.common.outputs.private_zone_id
  external_domain              = data.terraform_remote_state.common.outputs.external_domain
  public_zone_id               = data.terraform_remote_state.common.outputs.public_zone_id
  environment_identifier       = data.terraform_remote_state.common.outputs.environment_identifier
  common_name                  = data.terraform_remote_state.common.outputs.common_name
  short_environment_identifier = data.terraform_remote_state.common.outputs.short_environment_identifier
  region                       = var.region
  tags                         = data.terraform_remote_state.common.outputs.common_tags
  private_subnet_ids           = [data.terraform_remote_state.common.outputs.private_subnet_ids]
  cluster_size                 = var.elasticCache_cluster_size
  instance_type                = var.elastiCache_instance_type
  engine_version               = var.elastiCache_engine_version

  security_group_ids = [
    data.terraform_remote_state.security-groups.outputs.security_groups_sg_elasticache_sg_id,
  ]
}

####################################################
# ElasticCache - memcached
####################################################
# subnet group
module "subnet_group" {
  source  = "../modules/elastiCache/subnet_group"
  name    = local.common_name
  subnets = flatten(local.private_subnet_ids)
}

#parameter_group
module "parameter_group" {
  source = "../modules/elastiCache/parameter_group"
  name   = local.common_name
  family = "memcached1.5"
}

# cluster
module "memcached" {
  source               = "../modules/elastiCache/memcached"
  cluster_id           = "${local.short_environment_identifier}-ec"
  engine_version       = local.engine_version
  instance_type        = local.instance_type
  tags                 = local.tags
  cluster_size         = local.cluster_size
  parameter_group_name = module.parameter_group.id
  subnet_group_name    = module.subnet_group.name
  security_group_ids   = local.security_group_ids
  domain               = local.internal_domain
  zone_id              = local.private_zone_id
}

