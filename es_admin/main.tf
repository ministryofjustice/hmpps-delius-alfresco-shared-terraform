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
### Getting the certs details
#-------------------------------------------------------------
data "terraform_remote_state" "certs" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "alfresco/certs/terraform.tfstate"
    region = "${var.region}"
  }
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
### Getting the shared monitoring details
#-------------------------------------------------------------
data "terraform_remote_state" "monitoring" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "shared-monitoring/terraform.tfstate"
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

  owners = ["${data.terraform_remote_state.common.common_account_id}", "895523100917"] # MOJ
}

#-------------------------------------------------------------
### Getting ACM Cert
#-------------------------------------------------------------
data "aws_acm_certificate" "cert" {
  domain      = "*.${data.terraform_remote_state.common.external_domain}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

####################################################
# Locals
####################################################

locals {
  ami_id                       = "${data.aws_ami.ami.id}"
  account_id                   = "${data.terraform_remote_state.common.common_account_id}"
  vpc_id                       = "${data.terraform_remote_state.common.vpc_id}"
  internal_domain              = "${data.terraform_remote_state.common.internal_domain}"
  private_zone_id              = "${data.terraform_remote_state.common.private_zone_id}"
  public_zone_id               = "${data.terraform_remote_state.common.public_zone_id}"
  external_domain              = "${data.terraform_remote_state.common.external_domain}"
  environment_identifier       = "${data.terraform_remote_state.common.environment_identifier}"
  common_name                  = "${data.terraform_remote_state.common.short_environment_identifier}"
  short_environment_identifier = "${data.terraform_remote_state.common.short_environment_identifier}"
  region                       = "${var.region}"
  environment                  = "${data.terraform_remote_state.common.environment}"
  tags                         = "${data.terraform_remote_state.common.common_tags}"
  instance_profile             = "${data.terraform_remote_state.iam.iam_instance_es_admin_profile_name}"
  ssh_deployer_key             = "${data.terraform_remote_state.common.common_ssh_deployer_key}"
  s3bucket                     = "${data.terraform_remote_state.s3bucket.s3bucket}"
  bastion_inventory            = "${var.bastion_inventory}"
  application                  = "es-admin"
  config-bucket                = "${data.terraform_remote_state.common.common_s3-config-bucket}"
  certificate_arn              = "${data.aws_acm_certificate.cert.arn}"
  public_subnet_ids            = ["${data.terraform_remote_state.common.public_subnet_ids}"]
  private_subnet_ids           = ["${data.terraform_remote_state.common.private_subnet_ids}"]
  ssm_tls_private_key          = "${data.terraform_remote_state.certs.self_signed_server_ssm_private_key_name}"
  ssm_tls_cert                 = "${data.terraform_remote_state.certs.self_signed_server_ssm_cert_pem_name}"
  ssm_tls_ca_cert              = "${data.terraform_remote_state.certs.self_signed_ca_ssm_cert_pem_name}"
  elk_bucket_name              = "${data.terraform_remote_state.monitoring.monitoring_server_bucket_name}"
  elk_lb_dns                   = "${data.terraform_remote_state.monitoring.elasticsearch_cluster_lb}"

  instance_security_groups = [
    "${data.terraform_remote_state.monitoring.instance_security_groups}",
    "${data.terraform_remote_state.security-groups.security_groups_map["mon_jenkins"]}",
  ]
}
