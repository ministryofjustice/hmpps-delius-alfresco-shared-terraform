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
### Getting the vpc details
#-------------------------------------------------------------
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "vpc/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the current running account id
#-------------------------------------------------------------
data "aws_caller_identity" "current" {}


####################################################
# Locals
####################################################

locals {
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  cidr_block = "${data.terraform_remote_state.vpc.vpc_cidr_block}"
  internal_domain = "${var.alfresco_app_name}-${var.environment}.internal"
  tags = "${merge(data.terraform_remote_state.vpc.tags, map("sub-project", "${var.alfresco_app_name}"))}"
}


#######################################
# SECURITY GROUPS
#######################################

resource "aws_security_group" "vpc-sg-outbound" {
  name        = "${var.environment_identifier}-${var.alfresco_app_name}-sg-outbound"
  description = "security group for ${var.environment_identifier}-${var.alfresco_app_name}-traffic"
  vpc_id      = "${local.vpc_id}"

  egress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "${var.environment_identifier}-${var.alfresco_app_name}"
  }

  egress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "${var.environment_identifier}-${var.alfresco_app_name}"
  }

  egress {
    from_port   = "2514"
    protocol    = "tcp"
    to_port     = "2514"
    description = "Monitoring traffic rsyslog"
    cidr_blocks = ["${local.cidr_block}"]
  }

  egress {
    from_port   = "2514"
    protocol    = "udp"
    to_port     = "2514"
    description = "Monitoring traffic rsyslog"
    cidr_blocks = ["${local.cidr_block}"]
  }

  egress {
    from_port   = "5000"
    protocol    = "tcp"
    to_port     = "5000"
    description = "Monitoring traffic logstash"
    cidr_blocks = ["${local.cidr_block}"]
  }

  egress {
    from_port   = "9200"
    protocol    = "tcp"
    to_port     = "9200"
    description = "Monitoring traffic elasticsearch"
    cidr_blocks = ["${local.cidr_block}"]
  }

  tags = "${merge(local.tags, map("Name", "${var.environment_identifier}-${var.alfresco_app_name}-outbound-traffic"))}"
}

# #-------------------------------------------
# ### S3 bucket for config
# #--------------------------------------------
module "s3config_bucket" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//s3bucket//s3bucket_without_policy"
  s3_bucket_name = "${var.environment_identifier}-${var.alfresco_app_name}"
  tags           = "${local.tags}"
}

# #-------------------------------------------
# ### S3 bucket for logs
# #--------------------------------------------
module "s3_lb_logs_bucket" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//s3bucket//s3bucket_without_policy"
  s3_bucket_name = "${var.environment_identifier}-${var.alfresco_app_name}-lb-logs"
  tags           = "${local.tags}"
}

#-------------------------------------------
### Attaching S3 bucket policy to ALB logs bucket
#--------------------------------------------

data "template_file" "s3alb_logs_policy" {
  template = "${file("policies/${var.s3_lb_policy_file}")}"

  vars {
    s3_bucket_name   = "${module.s3_lb_logs_bucket.s3_bucket_name}"
    s3_bucket_prefix = "${var.short_environment_identifier}-*"
    aws_account_id   = "${data.aws_caller_identity.current.account_id}"
    lb_account_id    = "${var.lb_account_id}"
  }
}

module "s3alb_logs_policy" {
  source       = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//s3bucket//s3bucket_policy"
  s3_bucket_id = "${module.s3_lb_logs_bucket.s3_bucket_name}"
  policyfile   = "${data.template_file.s3alb_logs_policy.rendered}"
}

############################################
# DEPLOYER KEY FOR PROVISIONING
############################################

module "ssh_key" {
  source   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//ssh_key"
  keyname  = "${var.environment_identifier}-${var.alfresco_app_name}"
  rsa_bits = "4096"
}


# Add to SSM
module "create_parameter_ssh_key_private" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//ssm//parameter_store_file"
  parameter_name = "${var.environment_identifier}-${var.alfresco_app_name}-ssh-private-key"
  description    = "${var.environment_identifier}-${var.alfresco_app_name}-ssh-private-key"
  type           = "SecureString"
  value          = "${module.ssh_key.private_key_pem}"
  tags           = "${local.tags}"
}


module "create_parameter_ssh_key" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//ssm//parameter_store_file"
  parameter_name = "${var.environment_identifier}-${var.alfresco_app_name}-ssh-public-key"
  description    = "${var.environment_identifier}-${var.alfresco_app_name}-ssh-public-key"
  type           = "String"
  value          = "${module.ssh_key.public_key_openssh}"
  tags           = "${local.tags}"
}

############################################
# INTERNAL Route53
############################################
#Private internal zone for easier lookups
resource "aws_route53_zone" "internal_zone" {
  name   = "${local.internal_domain}"
  vpc_id = "${local.vpc_id}"
}

