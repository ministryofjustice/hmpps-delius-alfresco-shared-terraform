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
### Getting the asg details
#-------------------------------------------------------------
data "terraform_remote_state" "asg" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/asg/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the rds details
#-------------------------------------------------------------
data "terraform_remote_state" "rds" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/database/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the efs details
#-------------------------------------------------------------
data "terraform_remote_state" "efs" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/efs/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the es admin details
#-------------------------------------------------------------
data "terraform_remote_state" "es_admin" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/es_admin/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the latest amazon ami
#-------------------------------------------------------------

data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["HMPPS Base Docker Centos*"]
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

  owners = [data.terraform_remote_state.common.outputs.common_account_id, "895523100917"] # MOJ
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
  ami_id                       = data.aws_ami.ami.id
  account_id                   = data.terraform_remote_state.common.outputs.common_account_id
  vpc_id                       = data.terraform_remote_state.common.outputs.vpc_id
  internal_domain              = data.terraform_remote_state.common.outputs.internal_domain
  private_zone_id              = data.terraform_remote_state.common.outputs.private_zone_id
  public_zone_id               = data.terraform_remote_state.common.outputs.public_zone_id
  external_domain              = data.terraform_remote_state.common.outputs.external_domain
  environment_identifier       = data.terraform_remote_state.common.outputs.environment_identifier
  common_name                  = data.terraform_remote_state.common.outputs.short_environment_identifier
  short_environment_identifier = data.terraform_remote_state.common.outputs.short_environment_identifier
  region                       = var.region
  environment                  = data.terraform_remote_state.common.outputs.environment
  log_group                    = data.terraform_remote_state.es_admin.outputs.loggroup_name
  tags                         = data.terraform_remote_state.common.outputs.common_tags
  instance_profile             = data.terraform_remote_state.iam.outputs.iam_instance_es_admin_profile_name
  iam_role_arn                 = data.terraform_remote_state.iam.outputs.iam_instance_es_admin_role_arn
  ssh_deployer_key             = data.terraform_remote_state.common.outputs.common_ssh_deployer_key
  s3bucket                     = data.terraform_remote_state.s3bucket.outputs.s3bucket
  bastion_inventory            = var.bastion_inventory
  application                  = "es-admin"
  logs_kms_arn                 = data.terraform_remote_state.common.outputs.kms_arn
  config-bucket                = data.terraform_remote_state.common.outputs.common_s3-config-bucket
  certificate_arn              = data.aws_acm_certificate.cert.arn
  public_subnet_ids            = [data.terraform_remote_state.common.outputs.public_subnet_ids]
  private_subnet_ids           = [data.terraform_remote_state.common.outputs.private_subnet_ids]
  elk_bucket_name              = data.terraform_remote_state.s3bucket.outputs.elk_backups_bucket_name
  asg_prefix                   = data.terraform_remote_state.asg.outputs.asg_autoscale_name
  storage_s3bucket             = data.terraform_remote_state.s3bucket.outputs.s3bucket
  backups_bucket               = data.terraform_remote_state.s3bucket.outputs.alf_backups_bucket_name
  storage_kms_arn              = data.terraform_remote_state.s3bucket.outputs.s3bucket_kms_arn
  db_username_ssm              = data.terraform_remote_state.rds.outputs.rds_creds["db_username_ssm_param"]
  db_name                      = data.terraform_remote_state.rds.outputs.rds_creds["db_name"]
  db_password_ssm              = data.terraform_remote_state.rds.outputs.rds_creds["db_password_ssm_param"]
  db_host                      = data.terraform_remote_state.rds.outputs.rds_db_instance_endpoint_cname
  mon_jenkins_sg               = data.terraform_remote_state.security-groups.outputs.security_groups_map["mon_jenkins"]
  sg_rds_id                    = data.terraform_remote_state.security-groups.outputs.security_groups_sg_rds_id
  alf_efs_dns_name             = data.terraform_remote_state.efs.outputs.efs_dns_name
  alf_efs_sg                   = data.terraform_remote_state.security-groups.outputs.security_groups_sg_efs_sg_id
  source_bucket                = "tf-eu-west-2-hmpps-delius-prod-alfresco-storage-s3bucket"
  common_sgs                   = [local.esadmin_sgs, aws_security_group.redis.id]

  monitoring_groups = [
    data.terraform_remote_state.network-security-groups.outputs.sg_ssh_bastion_in_id,
    data.terraform_remote_state.network-security-groups.outputs.sg_mon_efs,
    data.terraform_remote_state.network-security-groups.outputs.sg_monitoring,
    data.terraform_remote_state.network-security-groups.outputs.sg_elasticsearch,
  ]

  esadmin_sgs = [
    data.terraform_remote_state.network-security-groups.outputs.sg_ssh_bastion_in_id,
    data.terraform_remote_state.common.outputs.common_sg_outbound_id,
  ]

  instance_security_groups = [
    local.monitoring_groups,
    data.terraform_remote_state.security-groups.outputs.security_groups_map["mon_jenkins"],
  ]
}

