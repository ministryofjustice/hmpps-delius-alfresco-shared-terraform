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
### Getting the current running account id
#-------------------------------------------------------------
data "aws_caller_identity" "current" {}

#######################################
# SECURITY GROUPS
#######################################

# resource "aws_security_group" "vpc-sg-outbound" {
#   name        = "${var.environment_identifier}-vpc-sg-outbound"
#   description = "security group for ${var.environment_identifier}-vpc-outbound-traffic"
#   vpc_id      = "${module.vpc.vpc_id}"

#   egress {
#     from_port   = "80"
#     to_port     = "80"
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "${var.environment_identifier}-vpc"
#   }

#   egress {
#     from_port   = "443"
#     to_port     = "443"
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "${var.environment_identifier}-vpc"
#   }

#   egress {
#     from_port   = "2514"
#     protocol    = "tcp"
#     to_port     = "2514"
#     description = "Monitoring traffic rsyslog"
#     cidr_blocks = ["${var.cidr_block}"]
#   }

#   egress {
#     from_port   = "2514"
#     protocol    = "udp"
#     to_port     = "2514"
#     description = "Monitoring traffic rsyslog"
#     cidr_blocks = ["${var.cidr_block}"]
#   }

#   egress {
#     from_port   = "5000"
#     protocol    = "tcp"
#     to_port     = "5000"
#     description = "Monitoring traffic logstash"
#     cidr_blocks = ["${var.cidr_block}"]
#   }

#   egress {
#     from_port   = "9200"
#     protocol    = "tcp"
#     to_port     = "9200"
#     description = "Monitoring traffic elasticsearch"
#     cidr_blocks = ["${var.cidr_block}"]
#   }

#   tags = "${merge(var.tags, map("Name", "${var.environment_identifier}-outbound-traffic"))}"
# }

# #-------------------------------------------
# ### S3 bucket for config
# #--------------------------------------------
module "s3config_bucket" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//s3bucket//s3bucket_without_policy"
  s3_bucket_name = "${var.environment_identifier}-${var.alfresco_app_name}"
  tags           = "${var.tags}"
}

# #-------------------------------------------
# ### S3 bucket for logs
# #--------------------------------------------
module "s3_lb_logs_bucket" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//s3bucket//s3bucket_without_policy"
  s3_bucket_name = "${var.environment_identifier}-${var.alfresco_app_name}-lb-logs"
  tags           = "${var.tags}"
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
  source       = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//s3bucket//s3bucket_policy"
  s3_bucket_id = "${module.s3_lb_logs_bucket.s3_bucket_name}"
  policyfile   = "${data.template_file.s3alb_logs_policy.rendered}"
}

############################################
# DEPLOYER KEY FOR PROVISIONING
############################################


# module "ssh_key" {
#   source   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//ssh_key"
#   keyname  = "${var.environment_identifier}"
#   rsa_bits = "4096"
# }


# # Add to SSM
# module "create_parameter_ssh_key_private" {
#   source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//ssm//parameter_store_file"
#   parameter_name = "${var.environment_identifier}-ssh-private-key"
#   description    = "${var.environment_identifier}-ssh-private-key"
#   type           = "SecureString"
#   value          = "${module.ssh_key.private_key_pem}"
#   tags           = "${var.tags}"
# }


# module "create_parameter_ssh_key" {
#   source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//ssm//parameter_store_file"
#   parameter_name = "${var.environment_identifier}-ssh-public-key"
#   description    = "${var.environment_identifier}-ssh-public-key"
#   type           = "String"
#   value          = "${module.ssh_key.public_key_openssh}"
#   tags           = "${var.tags}"
# }


# Private internal zone for easier lookups
# resource "aws_route53_zone" "internal_zone" {
#   name   = "${var.route53_internal_domain}"
#   vpc_id = "${module.vpc.vpc_id}"
# }

