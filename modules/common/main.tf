####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

#-------------------------------------------------------------
### Getting the current running account id
#-------------------------------------------------------------
data "aws_caller_identity" "current" {}

####################################################
# Locals
####################################################

locals {
  vpc_id          = "${var.vpc_id}"
  cidr_block      = "${var.cidr_block}"
  internal_domain = "${var.internal_domain}"
  tags            = "${var.tags}"
  common_name     = "${var.common_name}"
}

#######################################
# SECURITY GROUPS
#######################################
resource "aws_security_group" "vpc-sg-outbound" {
  name        = "${local.common_name}-sg-outbound"
  description = "security group for ${local.common_name}-traffic"
  vpc_id      = "${local.vpc_id}"
  tags        = "${merge(local.tags, map("Name", "${local.common_name}-outbound-traffic"))}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "http" {
  security_group_id = "${aws_security_group.vpc-sg-outbound.id}"
  type              = "egress"
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "${local.common_name}-http"
  count             = "${var.sg_create_outbound_web_rules}"
}

resource "aws_security_group_rule" "https" {
  security_group_id = "${aws_security_group.vpc-sg-outbound.id}"
  type              = "egress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "${local.common_name}-https"
  count             = "${var.sg_create_outbound_web_rules}"
}

# #-------------------------------------------
# ### S3 bucket for config
# #--------------------------------------------
module "s3config_bucket" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//s3bucket//s3bucket_without_policy"
  s3_bucket_name = "${local.common_name}"
  tags           = "${local.tags}"
  versioning     = false
}

# #-------------------------------------------
# ### S3 bucket for logs
# #--------------------------------------------
module "s3_lb_logs_bucket" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//s3bucket//s3bucket_without_policy"
  s3_bucket_name = "${local.common_name}-lb-logs"
  tags           = "${local.tags}"
}

#-------------------------------------------
### Attaching S3 bucket policy to ALB logs bucket
#--------------------------------------------

data "template_file" "s3alb_logs_policy" {
  template = "${file("${var.s3_lb_policy_file}")}"

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

###############################################
# RDS DB PASSWORD
###############################################
resource "random_string" "rds_password" {
  length  = 20
  special = true
}

# Add to SSM
resource "aws_ssm_parameter" "param" {
  name        = "${local.common_name}-rds-db-password"
  description = "${local.common_name}-rds-db-password"
  type        = "SecureString"
  value       = "${sha256(bcrypt(random_string.rds_password.result))}"

  tags = "${merge(local.tags, map("Name", "${local.common_name}-rds-db-password"))}"

  lifecycle {
    ignore_changes = ["value"]
  }
}
