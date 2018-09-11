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

#-------------------------------------------------------------
### Getting ACM Cert
#-------------------------------------------------------------
data "aws_acm_certificate" "cert" {
  domain      = "*.${data.terraform_remote_state.common.external_domain}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

#-------------------------------------------------------------
### Getting the s3 details
#-------------------------------------------------------------
data "terraform_remote_state" "s3bucket" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/s3buckets/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the IAM details
#-------------------------------------------------------------
data "terraform_remote_state" "iam" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/iam/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the rds details
#-------------------------------------------------------------
data "terraform_remote_state" "rds" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/rds/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the security groups details
#-------------------------------------------------------------
data "terraform_remote_state" "security-groups" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/security-groups/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the security groups details
#-------------------------------------------------------------
data "terraform_remote_state" "asg" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/asg/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the security groups details
#-------------------------------------------------------------
data "terraform_remote_state" "self_certs" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/certs/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the latest amazon ami
#-------------------------------------------------------------
data "aws_ami" "amazon_ami" {
  most_recent = true

  filter {
    name   = "description"
    values = ["Amazon Linux AMI *"]
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

  owners = ["591542846629"] # AWS
}

####################################################
# Locals
####################################################

locals {
  ami_id                         = "${data.aws_ami.amazon_ami.id}"
  account_id                     = "${data.terraform_remote_state.common.common_account_id}"
  vpc_id                         = "${data.terraform_remote_state.common.vpc_id}"
  cidr_block                     = "${data.terraform_remote_state.common.vpc_cidr_block}"
  internal_domain                = "${data.terraform_remote_state.common.internal_domain}"
  private_zone_id                = "${data.terraform_remote_state.common.private_zone_id}"
  external_domain                = "${data.terraform_remote_state.common.external_domain}"
  public_zone_id                 = "${data.terraform_remote_state.common.public_zone_id}"
  environment_identifier         = "${data.terraform_remote_state.common.environment_identifier}"
  short_environment_identifier   = "${data.terraform_remote_state.common.short_environment_identifier}"
  region                         = "${var.region}"
  alfresco_app_name              = "${data.terraform_remote_state.common.alfresco_app_name}"
  environment                    = "${data.terraform_remote_state.common.environment}"
  tags                           = "${data.terraform_remote_state.common.common_tags}"
  private_subnet_map             = "${data.terraform_remote_state.common.private_subnet_map}"
  lb_security_groups             = ["${data.terraform_remote_state.security-groups.security_groups_sg_external_lb_id}"]
  access_logs_bucket             = "${data.terraform_remote_state.common.common_s3_lb_logs_bucket}"
  ssh_deployer_key               = "${data.terraform_remote_state.common.common_ssh_deployer_key}"
  s3bucket_kms_id                = "${data.terraform_remote_state.s3bucket.s3bucket_kms_id}"
  s3bucket                       = "${data.terraform_remote_state.s3bucket.s3bucket}"
  monitoring_server_internal_url = "${data.terraform_remote_state.common.monitoring_server_internal_url}"
  app_hostnames                  = "${data.terraform_remote_state.common.app_hostnames}"
  certificate_arn                = ["${data.aws_acm_certificate.cert.arn}"]
  image_url                      = "mojdigitalstudio/hmpps-nginx-non-confd"
  image_version                  = "latest"
  public_subnet_ids              = ["${data.terraform_remote_state.common.public_subnet_ids}"]
  public_cidr_block              = ["${data.terraform_remote_state.common.db_cidr_block}"]
  app_name                       = "nginx"
  config-bucket                  = "${data.terraform_remote_state.common.common_s3-config-bucket}"
  ecs_service_role               = "${data.terraform_remote_state.iam.iam_role_ext_ecs_role_arn}"
  service_desired_count          = "2"
  cloudwatch_log_retention       = "${var.cloudwatch_log_retention}"

  instance_profile = "${data.terraform_remote_state.iam.iam_policy_ext_app_instance_profile_name}"

  self_signed_ssm = {
    ca_cert = "${data.terraform_remote_state.self_certs.self_signed_ca_ssm_cert_pem_name}"
    cert    = "${data.terraform_remote_state.self_certs.self_signed_server_ssm_cert_pem_name}"
    key     = "${data.terraform_remote_state.self_certs.self_signed_server_ssm_private_key_name}"
  }

  instance_security_groups = [
    "${data.terraform_remote_state.security-groups.security_groups_sg_external_instance_id}",
    "${data.terraform_remote_state.common.common_sg_outbound_id}",
    "${data.terraform_remote_state.common.monitoring_server_client_sg_id}",
  ]
}

####################################################
# NGINX - Application Specific
####################################################
module "ecs-nginx" {
  source                         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=issue-62//projects//alfresco//nginx"
  app_name                       = "${local.app_name}"
  certificate_arn                = ["${local.certificate_arn}"]
  image_url                      = "${local.image_url}"
  image_version                  = "${local.image_version}"
  short_environment_identifier   = "${local.short_environment_identifier}"
  environment_identifier         = "${local.environment_identifier}"
  environment                    = "${local.environment}"
  public_subnet_ids              = ["${local.public_subnet_ids}"]
  tags                           = "${local.tags}"
  instance_security_groups       = ["${local.instance_security_groups}"]
  lb_security_groups             = ["${local.lb_security_groups}"]
  vpc_id                         = "${local.vpc_id}"
  config_bucket                  = "${local.config-bucket}"
  access_logs_bucket             = "${local.access_logs_bucket}"
  public_zone_id                 = "${local.public_zone_id}"
  external_domain                = "${local.external_domain}"
  alb_backend_port               = "443"
  alb_http_port                  = "80"
  alb_https_port                 = "443"
  deregistration_delay           = "90"
  backend_app_port               = "80"
  backend_app_protocol           = "HTTP"
  backend_app_template_file      = "template.json"
  backend_check_app_path         = "/"
  backend_check_interval         = "120"
  backend_ecs_cpu_units          = "256"
  backend_ecs_desired_count      = "1"
  backend_ecs_memory             = "2048"
  backend_healthy_threshold      = "2"
  backend_maxConnections         = "500"
  backend_maxConnectionsPerRoute = "200"
  backend_return_code            = "200,302"
  backend_timeout                = "60"
  backend_timeoutInSeconds       = "60"
  backend_timeoutRetries         = "10"
  backend_unhealthy_threshold    = "10"
  target_type                    = "instance"
  cloudwatch_log_retention       = "${local.cloudwatch_log_retention}"
  keys_dir                       = "/opt/keys"
  kibana_host                    = "${local.monitoring_server_internal_url}"
  app_hostnames                  = "${local.app_hostnames}"
  region                         = "${local.region}"
  ecs_service_role               = "${local.ecs_service_role}"
  service_desired_count          = "${local.service_desired_count}"
  self_signed_ssm                = "${local.self_signed_ssm}"
  service_desired_count          = "2"
  user_data                      = "../user_data/nginx_user_data.sh"
  volume_size                    = "20"
  ebs_device_name                = "/dev/xvdb"
  ebs_volume_type                = "standard"
  ebs_volume_size                = "10"
  ebs_encrypted                  = "true"
  instance_type                  = "t2.medium"
  asg_desired                    = "2"
  asg_max                        = "2"
  asg_min                        = "2"
  associate_public_ip_address    = true
  ami_id                         = "${local.ami_id}"
  instance_profile               = "${local.instance_profile}"
  ssh_deployer_key               = "${local.ssh_deployer_key}"
}
