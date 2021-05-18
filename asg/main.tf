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

data "terraform_remote_state" "elk-service" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/elk-service/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the elk-migration details
#-------------------------------------------------------------
data "terraform_remote_state" "solr" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/solr/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the latest amazon ami
#-------------------------------------------------------------
data "aws_ami" "amazon_ami" {
  most_recent = true
  owners      = [var.alf_account_ids["eng-non-prod"]]

  filter {
    name   = "name"
    values = [local.alfresco_asg_props["ami_name"]]
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
  alfresco_asg_props           = merge(var.alfresco_asg_props, var.alf_asg_map, var.alf_config_map)
  ami_id                       = var.environment_name != "alfresco-dev" ? local.alfresco_asg_props["asg_ami"] : data.aws_ami.amazon_ami.id
  account_id                   = data.terraform_remote_state.common.outputs.common_account_id
  vpc_id                       = data.terraform_remote_state.common.outputs.vpc_id
  cidr_block                   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  allowed_cidr_block           = [data.terraform_remote_state.common.outputs.vpc_cidr_block]
  internal_domain              = data.terraform_remote_state.common.outputs.internal_domain
  private_zone_id              = data.terraform_remote_state.common.outputs.private_zone_id
  public_zone_id               = data.terraform_remote_state.common.outputs.public_zone_id
  external_domain              = data.terraform_remote_state.common.outputs.external_domain
  environment_identifier       = data.terraform_remote_state.common.outputs.environment_identifier
  common_name                  = data.terraform_remote_state.common.outputs.common_name
  short_environment_identifier = data.terraform_remote_state.common.outputs.short_environment_identifier
  region                       = var.region
  alfresco_app_name            = data.terraform_remote_state.common.outputs.alfresco_app_name
  environment                  = data.terraform_remote_state.common.outputs.environment
  tags                         = data.terraform_remote_state.common.outputs.common_tags
  private_subnet_map           = data.terraform_remote_state.common.outputs.private_subnet_map
  lb_security_groups           = [data.terraform_remote_state.security-groups.outputs.security_groups_sg_external_lb_id]
  instance_profile             = data.terraform_remote_state.iam.outputs.iam_policy_int_app_instance_profile_name
  access_logs_bucket           = data.terraform_remote_state.common.outputs.common_s3_lb_logs_bucket
  ssh_deployer_key             = data.terraform_remote_state.common.outputs.common_ssh_deployer_key
  s3bucket_kms_id              = data.terraform_remote_state.s3bucket.outputs.s3bucket_kms_id
  s3bucket                     = data.terraform_remote_state.s3bucket.outputs.s3bucket
  db_name                      = data.terraform_remote_state.rds.outputs.rds_creds["db_name"]
  db_username_ssm              = data.terraform_remote_state.rds.outputs.rds_creds["db_username_ssm_param"]
  db_password_ssm              = data.terraform_remote_state.rds.outputs.rds_creds["db_password_ssm_param"]
  db_host                      = data.terraform_remote_state.rds.outputs.rds_db_instance_endpoint_cname # data.terraform_remote_state.rds.outputs.aurora["cluster_endpoint"]
  solr_host                    = "solr.${local.internal_domain}"
  app_hostnames                = data.terraform_remote_state.common.outputs.app_hostnames
  bastion_inventory            = var.bastion_inventory
  jvm_memory                   = var.alfresco_jvm_memory
  config-bucket                = data.terraform_remote_state.common.outputs.common_s3-config-bucket
  tomcat_host                  = "alfresco"
  certificate_arn              = data.aws_acm_certificate.cert.arn
  public_subnet_ids            = [data.terraform_remote_state.common.outputs.public_subnet_ids]
  messaging_broker_url         = data.terraform_remote_state.amazonmq.outputs.amazon_mq_broker_failover_connection_url
  messaging_broker_password    = "${data.terraform_remote_state.common.outputs.credentials_ssm_path}/weblogic/spg-domain/remote_broker_password"
  logs_kms_arn                 = data.terraform_remote_state.common.outputs.kms_arn

  instance_security_groups = [
    data.terraform_remote_state.security-groups.outputs.security_groups_sg_internal_instance_id,
    data.terraform_remote_state.common.outputs.common_sg_outbound_id,
    data.terraform_remote_state.elk-service.outputs.elk_service["access_sg"],
    data.terraform_remote_state.security-groups.outputs.security_groups_bastion_in_sg_id,
    data.terraform_remote_state.security-groups.outputs.security_groups_map["mon_jenkins"],
  ]

  solr_config = {
    solr_host = data.terraform_remote_state.solr.outputs.alb_dns_internal
    solr_port = 8983
  }
  https_listener_rules = [
    {
      https_listener_index = 0
      priority             = 50
      actions = [
        {
          type               = "forward"
          target_group_index = 0
        }
      ]
      conditions = [{
        source_ips = data.terraform_remote_state.common.outputs.nat_gateway_ips
      }]
    },
    {
      https_listener_index = 0
      priority             = 55
      actions = [
        {
          type               = "forward"
          target_group_index = 0
        }
      ]
      conditions = [{
        source_ips = data.terraform_remote_state.common.outputs.bastion_cidr_ranges
      }]
    },
    {
      https_listener_index = 0
      priority             = 60
      actions = [
        {
          type               = "forward"
          target_group_index = 0
        }
      ]
      conditions = [{
        source_ips = [local.alfresco_asg_props["vpn_ip"]]
      }]
    },
    {
      https_listener_index = 0
      priority             = 20
      actions = [
        {
          type               = "forward"
          target_group_index = 0
        }
      ]
      conditions = [{
        path_patterns = ["/alfresco/aos/*", "/alfresco/share/*"]
      }]
    },
  ]
}

####################################################
# ASG - Application Specific
####################################################
module "asg" {
  source                       = "../modules/asg"
  alfresco_app_name            = local.alfresco_app_name
  app_hostnames                = local.app_hostnames
  environment_identifier       = local.environment_identifier
  common_name                  = local.common_name
  tags                         = local.tags
  vpc_id                       = local.vpc_id
  private_subnet_ids           = local.private_subnet_map
  short_environment_identifier = local.short_environment_identifier
  instance_profile             = local.instance_profile
  access_logs_bucket           = local.access_logs_bucket
  ssh_deployer_key             = local.ssh_deployer_key
  bucket_kms_key_id            = local.s3bucket_kms_id
  alfresco_s3bucket            = local.s3bucket
  lb_security_groups           = flatten(local.lb_security_groups)
  internal                     = false
  az_asg_desired               = var.restoring == "enabled" ? 0 : lookup(local.alfresco_asg_props, "asg_desired", 1)
  az_asg_min                   = var.restoring == "enabled" ? 0 : lookup(local.alfresco_asg_props, "asg_min", 1)
  az_asg_max                   = var.restoring == "enabled" ? 0 : lookup(local.alfresco_asg_props, "asg_max", 1)
  default_cooldown             = lookup(local.alfresco_asg_props, "default_cooldown", 120)
  alf_deploy_iwp_fix           = lookup(local.alfresco_asg_props, "alf_deploy_iwp_fix", 0)
  cloudwatch_log_retention     = var.alf_cloudwatch_log_retention
  zone_id                      = local.private_zone_id
  external_domain              = local.external_domain
  internal_domain              = local.internal_domain
  db_name                      = local.db_name
  db_username                  = local.db_username_ssm
  db_password                  = local.db_password_ssm
  db_host                      = local.db_host
  environment                  = local.environment
  region                       = local.region
  ami_id                       = local.ami_id
  account_id                   = local.account_id
  elasticsearch_props = {
    url          = data.terraform_remote_state.elk-service.outputs.elk_service["es_url"]
    cluster_name = data.terraform_remote_state.elk-service.outputs.elk_service["domain_name"]
  }
  messaging_broker_url      = local.messaging_broker_url
  messaging_broker_password = local.messaging_broker_password
  bastion_inventory         = local.bastion_inventory
  keys_dir                  = "/opt/keys"
  config_bucket             = local.config-bucket
  tomcat_host               = local.tomcat_host
  certificate_arn           = local.certificate_arn
  public_subnet_ids         = flatten(local.public_subnet_ids)
  public_zone_id            = local.public_zone_id
  health_check_grace_period = lookup(local.alfresco_asg_props, "health_check_grace_period", 900)
  logs_kms_arn              = local.logs_kms_arn
  min_elb_capacity          = lookup(local.alfresco_asg_props, "min_elb_capacity", 1)
  wait_for_capacity_timeout = lookup(local.alfresco_asg_props, "wait_for_capacity_timeout", "30m")
  # ASG
  service_desired_count       = "3"
  user_data                   = "../user_data/user_data.sh"
  volume_size                 = var.alfresco_volume_size
  ebs_device_name             = "/dev/xvdb"
  ebs_volume_type             = "standard"
  ebs_volume_size             = lookup(local.alfresco_asg_props, "ebs_volume_size", 512)
  ebs_encrypted               = "true"
  instance_type               = lookup(local.alfresco_asg_props, "asg_instance_type", "m4.xlarge")
  associate_public_ip_address = false
  cache_home                  = "/srv/cache"
  jvm_memory                  = local.jvm_memory
  instance_security_groups    = flatten(local.instance_security_groups)
  solr_config                 = local.solr_config
  source_code_versions        = var.source_code_versions
  solr_cmis_managed           = var.solr_cmis_managed
  https_listener_rules        = local.https_listener_rules
}

