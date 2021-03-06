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

data "terraform_remote_state" "network-security-groups" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "security-groups/terraform.tfstate"
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

data "aws_ami" "aws_ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  # Amazon Linux 2 optimised ECS instance
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*"]
  }

  # correct arch
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  # Owned by Amazon
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
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

#-------------------------------------------------------------
### Getting config bucket details
#-------------------------------------------------------------

data "aws_s3_bucket" "config_bucket" {
  bucket = data.terraform_remote_state.common.outputs.common_s3-config-bucket
}

#-------------------------------------------------------------
## Getting creds
#-------------------------------------------------------------
data "aws_ssm_parameter" "elk_user" {
  name = local.elk_user
}

data "aws_ssm_parameter" "elk_password" {
  name = local.elk_password
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
  common_name                  = "${data.terraform_remote_state.common.outputs.short_environment_identifier}-mig"
  short_environment_identifier = data.terraform_remote_state.common.outputs.short_environment_identifier
  region                       = var.region
  ssm_path                     = data.terraform_remote_state.common.outputs.credentials_ssm_path
  elk_user                     = "${local.ssm_path}/alfresco/alfresco/elk_user"
  elk_password                 = "${local.ssm_path}/alfresco/alfresco/elk_password"
  environment                  = data.terraform_remote_state.common.outputs.environment
  tags                         = data.terraform_remote_state.common.outputs.common_tags
  instance_profile             = data.terraform_remote_state.iam.outputs.iam_instance_es_admin_profile_name
  ssh_deployer_key             = data.terraform_remote_state.common.outputs.common_ssh_deployer_key
  s3bucket                     = data.terraform_remote_state.s3bucket.outputs.s3bucket
  bastion_inventory            = var.bastion_inventory
  application                  = "esmigration"
  service_discovery_domain     = "${local.application}-${local.internal_domain}"
  config-bucket                = data.terraform_remote_state.common.outputs.common_s3-config-bucket
  config_bucket_arn            = data.aws_s3_bucket.config_bucket.arn
  certificate_arn              = data.aws_acm_certificate.cert.arn
  public_subnet_ids            = [data.terraform_remote_state.common.outputs.public_subnet_ids]
  private_subnet_ids           = [data.terraform_remote_state.common.outputs.private_subnet_ids]
  elk_bucket_name              = data.terraform_remote_state.s3bucket.outputs.elk_backups_bucket_name
  elk_bucket_arn               = data.terraform_remote_state.s3bucket.outputs.elk_backups_bucket_arn
  es_host_fqdn                 = "alf5es.${local.external_domain}"
  es_host_url                  = "https://${local.es_host_fqdn}"
  kibana_host_fqdn             = "alf5kibana.${local.external_domain}"
  kibana_host_url              = "https://${local.kibana_host_fqdn}"
  logstash_host_fqdn           = "alf5logstash.${local.internal_domain}"
  storage_s3bucket             = data.terraform_remote_state.s3bucket.outputs.s3bucket
  backups_bucket               = data.terraform_remote_state.s3bucket.outputs.alf_backups_bucket_name
  storage_kms_arn              = data.terraform_remote_state.s3bucket.outputs.s3bucket_kms_arn
  mon_jenkins_sg               = data.terraform_remote_state.security-groups.outputs.security_groups_map["mon_jenkins"]
  sg_rds_id                    = data.terraform_remote_state.security-groups.outputs.security_groups_sg_rds_id
  alf_efs_dns_name             = data.terraform_remote_state.efs.outputs.efs_dns_name
  efs_mount_path               = "/opt/es_backup"
  es_home_dir                  = "/usr/share/elasticsearch"
  alf_efs_sg                   = data.terraform_remote_state.security-groups.outputs.security_groups_sg_efs_sg_id
  migration_mount_path         = "/opt/local"
  access_logs_bucket           = data.terraform_remote_state.common.outputs.common_s3_lb_logs_bucket
  port                         = 9200
  protocol                     = "HTTP"
  image_url                    = var.elk_migration_props["image_url"]
  service_desired_count        = var.elk_migration_props["ecs_service_desired_count"]
  logs_kms_arn                 = data.terraform_remote_state.common.outputs.kms_arn

  instance_security_groups = [
    data.terraform_remote_state.network-security-groups.outputs.sg_ssh_bastion_in_id,
    data.terraform_remote_state.network-security-groups.outputs.sg_mon_efs,
    data.terraform_remote_state.network-security-groups.outputs.sg_elasticsearch,
    data.terraform_remote_state.network-security-groups.outputs.sg_mon_jenkins,
  ]
  lb_security_groups = [
    data.terraform_remote_state.security-groups.outputs.security_groups_map["mon_jenkins"],
  ]
  external_lb_sgs = [
    data.terraform_remote_state.security-groups.outputs.security_groups_sg_external_lb_id,
    data.terraform_remote_state.security-groups.outputs.security_groups_map["mon_jenkins"],
  ]
  efs_security_groups = [
    local.mon_jenkins_sg,
  ]
}

