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
### Getting the security groups details
#-------------------------------------------------------------
data "terraform_remote_state" "self_certs" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/certs/terraform.tfstate"
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
### Getting the Amazon broker url
#-------------------------------------------------------------
data "terraform_remote_state" "amazonmq" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "${var.spg_messaging_broker_url_src == "data" ? "spg" : "alfresco"}/amazonmq/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the elk-migration details
#-------------------------------------------------------------
data "terraform_remote_state" "elk_migration" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/elk-migration/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the latest amazon ami
#-------------------------------------------------------------
data "aws_ami" "amazon_ami" {
  most_recent = true

  filter {
    name = "name"
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibility in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    values = [var.alfresco_asg_props["ami_name"]]
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
  owners = ["895523100917"]
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
  access_logs_bucket = data.terraform_remote_state.common.outputs.common_s3_lb_logs_bucket
  account_id         = data.terraform_remote_state.common.outputs.common_account_id
  alfresco_app_name  = data.terraform_remote_state.common.outputs.alfresco_app_name
  allowed_cidr_block = [values(
    data.terraform_remote_state.vpc.outputs.bastion_vpc_public_cidr,
  )]
  ami_id                         = var.environment_name != "alfresco-dev" ? var.alfresco_asg_props["asg_ami"] : data.aws_ami.amazon_ami.id
  app_hostnames                  = data.terraform_remote_state.common.outputs.app_hostnames
  bastion_inventory              = var.bastion_inventory
  certificate_arn                = data.aws_acm_certificate.cert.arn
  cidr_block                     = data.terraform_remote_state.common.outputs.vpc_cidr_block
  common_name                    = "${data.terraform_remote_state.common.outputs.short_environment_identifier}-solr"
  config-bucket                  = data.terraform_remote_state.common.outputs.common_s3-config-bucket
  db_host                        = data.terraform_remote_state.rds.outputs.rds_db_instance_endpoint_cname
  db_name                        = data.terraform_remote_state.rds.outputs.rds_creds["db_name"]
  db_password_ssm                = data.terraform_remote_state.rds.outputs.rds_creds["db_password_ssm_param"]
  db_username_ssm                = data.terraform_remote_state.rds.outputs.rds_creds["db_username_ssm_param"]
  environment                    = data.terraform_remote_state.common.outputs.environment
  environment_identifier         = data.terraform_remote_state.common.outputs.environment_identifier
  external_domain                = data.terraform_remote_state.common.outputs.external_domain
  instance_profile               = data.terraform_remote_state.iam.outputs.iam_policy_int_app_instance_profile_name
  internal_domain                = data.terraform_remote_state.common.outputs.internal_domain
  kibana_host                    = data.terraform_remote_state.elk_migration.outputs.kibana_host
  logs_kms_arn                   = data.terraform_remote_state.common.outputs.kms_arn
  logstash_host_fqdn             = data.terraform_remote_state.elk_migration.outputs.internal_logstash_host
  messaging_broker_password      = "${data.terraform_remote_state.common.outputs.credentials_ssm_path}/weblogic/spg-domain/remote_broker_password"
  monitoring_server_internal_url = data.terraform_remote_state.elk_migration.outputs.public_es_host_name
  private_subnet_map             = data.terraform_remote_state.common.outputs.private_subnet_map
  private_zone_id                = data.terraform_remote_state.common.outputs.private_zone_id
  public_subnet_ids              = [data.terraform_remote_state.common.outputs.public_subnet_ids]
  private_subnet_ids             = [data.terraform_remote_state.common.outputs.private_subnet_ids]
  public_zone_id                 = data.terraform_remote_state.common.outputs.public_zone_id
  region                         = var.region
  s3bucket                       = data.terraform_remote_state.s3bucket.outputs.s3bucket
  backups_bucket                 = data.terraform_remote_state.s3bucket.outputs.alf_backups_bucket_name
  s3bucket_kms_id                = data.terraform_remote_state.s3bucket.outputs.s3bucket_kms_id
  short_environment_identifier   = data.terraform_remote_state.common.outputs.short_environment_identifier
  ssh_deployer_key               = data.terraform_remote_state.common.outputs.common_ssh_deployer_key
  solr_port                      = 8983
  tags                           = data.terraform_remote_state.common.outputs.common_tags
  tomcat_host                    = "alfresco"
  vpc_id                         = data.terraform_remote_state.common.outputs.vpc_id
  messaging_broker_url           = data.terraform_remote_state.amazonmq.outputs.amazon_mq_broker_failover_connection_url

  self_signed_ssm = {
    ca_cert = data.terraform_remote_state.self_certs.outputs.self_signed_ca_ssm_cert_pem_name
    cert    = data.terraform_remote_state.self_certs.outputs.self_signed_server_ssm_cert_pem_name
    key     = data.terraform_remote_state.self_certs.outputs.self_signed_server_ssm_private_key_name
  }

  instance_security_groups = [
    data.terraform_remote_state.security-groups.outputs.security_groups_sg_internal_instance_id,
    data.terraform_remote_state.common.outputs.common_sg_outbound_id,
    data.terraform_remote_state.security-groups.outputs.security_groups_sg_monitoring_client,
    data.terraform_remote_state.security-groups.outputs.security_groups_bastion_in_sg_id,
  ]
}

