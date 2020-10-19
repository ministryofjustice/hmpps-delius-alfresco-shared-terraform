terraform {
  backend "s3" {
  }
}

####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################
#-------------------------------------------------------------
### Getting current
#-------------------------------------------------------------
data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}

#-------------------------------------------------------------
### Getting the vpc details
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
### Getting the nat gateways details
#-------------------------------------------------------------
data "terraform_remote_state" "nat" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "natgateway/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the engineer vpc
#-------------------------------------------------------------
data "terraform_remote_state" "remote_vpc" {
  backend = "s3"

  config = {
    bucket   = var.eng_remote_state_bucket_name
    key      = "vpc/terraform.tfstate"
    region   = var.region
    role_arn = var.eng_role_arn
  }
}

#-------------------------------------------------------------
### Getting the eng alfresco IAM role
#-------------------------------------------------------------
data "terraform_remote_state" "remote_iam" {
  backend = "s3"

  config = {
    bucket   = var.eng_remote_state_bucket_name
    key      = "alfresco/iam/terraform.tfstate"
    region   = var.region
    role_arn = var.eng_role_arn
  }
}

#-------------------------------------------------------------
### Getting the latest amazon ami
#-------------------------------------------------------------
data "aws_ami" "amazon_ami" {
  most_recent = true
  owners      = ["895523100917"]

  filter {
    name   = "name"
    values = ["HMPPS Alfresco master*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

####################################################
# Locals
####################################################

locals {
  vpc_id                       = data.terraform_remote_state.vpc.outputs.vpc_id
  cidr_block                   = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
  allowed_cidr_block           = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
  internal_domain              = data.terraform_remote_state.vpc.outputs.private_zone_name
  private_zone_id              = data.terraform_remote_state.vpc.outputs.private_zone_id
  external_domain              = data.terraform_remote_state.vpc.outputs.public_zone_name
  public_zone_id               = data.terraform_remote_state.vpc.outputs.public_zone_id
  common_name                  = "${var.environment_identifier}-${var.alfresco_app_name}"
  short_name                   = "${var.short_environment_identifier}-alf"
  lb_account_id                = var.lb_account_id
  region                       = var.region
  role_arn                     = var.role_arn
  alfresco_app_name            = var.alfresco_app_name
  environment_identifier       = var.environment_identifier
  short_environment_identifier = var.short_environment_identifier
  remote_state_bucket_name     = var.remote_state_bucket_name
  s3_lb_policy_file            = "../policies/s3_alb_policy.json"
  environment                  = var.environment_type

  tags = merge(
    var.tags,
    {
      "sub-project" = var.alfresco_app_name
    },
    {
      "source-hash" = "ignored"
    },
  )

  remote_iam_role      = data.terraform_remote_state.remote_iam.outputs.alfresco_iam_arn
  remote_config_bucket = data.terraform_remote_state.remote_vpc.outputs.s3-config-bucket
  ssh_deployer_key     = data.terraform_remote_state.vpc.outputs.ssh_deployer_key
  ssm_path             = "/${var.environment_name}/${var.project_name}"
  account_id           = data.aws_caller_identity.current.account_id

  app_hostnames = {
    internal = "${var.alfresco_app_name}-int"
    external = var.alfresco_app_name
  }

  private_subnet_map = {
    az1 = data.terraform_remote_state.vpc.outputs.vpc_private-subnet-az1
    az2 = data.terraform_remote_state.vpc.outputs.vpc_private-subnet-az2
    az3 = data.terraform_remote_state.vpc.outputs.vpc_private-subnet-az3
  }

  public_cidr_block = [
    data.terraform_remote_state.vpc.outputs.vpc_public-subnet-az1-cidr_block,
    data.terraform_remote_state.vpc.outputs.vpc_public-subnet-az2-cidr_block,
    data.terraform_remote_state.vpc.outputs.vpc_public-subnet-az3-cidr_block,
  ]

  private_cidr_block = [
    data.terraform_remote_state.vpc.outputs.vpc_private-subnet-az1-cidr_block,
    data.terraform_remote_state.vpc.outputs.vpc_private-subnet-az2-cidr_block,
    data.terraform_remote_state.vpc.outputs.vpc_private-subnet-az3-cidr_block,
  ]

  db_cidr_block = [
    data.terraform_remote_state.vpc.outputs.vpc_db-subnet-az1-cidr_block,
    data.terraform_remote_state.vpc.outputs.vpc_db-subnet-az2-cidr_block,
    data.terraform_remote_state.vpc.outputs.vpc_db-subnet-az3-cidr_block,
  ]

  db_subnet_ids = [
    data.terraform_remote_state.vpc.outputs.vpc_db-subnet-az1,
    data.terraform_remote_state.vpc.outputs.vpc_db-subnet-az2,
    data.terraform_remote_state.vpc.outputs.vpc_db-subnet-az3,
  ]

  nat_gateways_ips = [
    "${data.terraform_remote_state.nat.outputs.natgateway_common-nat-public-ip-az1}/32",
    "${data.terraform_remote_state.nat.outputs.natgateway_common-nat-public-ip-az2}/32",
    "${data.terraform_remote_state.nat.outputs.natgateway_common-nat-public-ip-az3}/32",
  ]
}

####################################################
# Common
####################################################
module "common" {
  source                       = "../modules/common"
  alfresco_app_name            = local.alfresco_app_name
  cidr_block                   = local.cidr_block
  common_name                  = local.common_name
  environment                  = local.environment
  environment_identifier       = local.environment_identifier
  internal_domain              = local.internal_domain
  lb_account_id                = local.lb_account_id
  region                       = local.region
  remote_state_bucket_name     = local.remote_state_bucket_name
  role_arn                     = local.role_arn
  private_zone_id              = local.private_zone_id
  s3_lb_policy_file            = local.s3_lb_policy_file
  short_environment_identifier = local.short_environment_identifier
  tags                         = local.tags
  vpc_id                       = local.vpc_id
}

