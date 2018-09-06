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
    key    = "${var.alfresco_app_name}/common/terraform.tfstate"
    region = "${var.region}"
  }
}

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

####################################################
# Locals
####################################################
locals {
  common_name = "${var.environment_identifier}-${var.alfresco_app_name}"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"
  cidr_block  = "${data.terraform_remote_state.vpc.vpc_cidr_block}"
  tags        = "${data.terraform_remote_state.common.common_tags}"

  public_cidr_block = [
    "${data.terraform_remote_state.vpc.vpc_public-subnet-az1-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_public-subnet-az2-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_public-subnet-az3-cidr_block}",
  ]

  private_cidr_block = [
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az1-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az2-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az3-cidr_block}",
  ]

  db_cidr_block = [
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az1-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az2-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az3-cidr_block}",
  ]
}

#######################################
# SECURITY GROUPS
#######################################

#-------------------------------------------------------------
### internal lb sg
#-------------------------------------------------------------
resource "aws_security_group" "internal_lb_sg" {
  name        = "${local.common_name}-lb-internal-sg"
  description = "security group for ${local.common_name}-lb-internal-sg"
  vpc_id      = "${local.vpc_id}"

  ingress {
    from_port = "${var.alb_http_port}"
    to_port   = "${var.alb_http_port}"
    protocol  = "tcp"

    cidr_blocks = [
      "${local.cidr_block}",
    ]

    description = "${local.common_name}-lb-internal-sg"
  }

  egress {
    from_port   = "${var.alb_backend_port}"
    to_port     = "${var.alb_backend_port}"
    protocol    = "tcp"
    cidr_blocks = ["${local.private_cidr_block}"]
    description = "${local.common_name}"
  }

  egress {
    from_port   = "${var.alb_http_port}"
    to_port     = "${var.alb_http_port}"
    protocol    = "tcp"
    cidr_blocks = ["${local.private_cidr_block}"]
    description = "${local.common_name}"
  }

  tags = "${merge(local.tags, map("Name", "${local.common_name}-lb-internal-sg"))}"
}

#-------------------------------------------------------------
### internal instance sg
#-------------------------------------------------------------
resource "aws_security_group" "internal_instance" {
  name        = "${local.common_name}-instance-internal-sg"
  description = "security group for ${local.common_name}-instance-internal-sg"
  vpc_id      = "${local.vpc_id}"

  ingress {
    from_port       = "${var.alb_backend_port}"
    to_port         = "${var.alb_backend_port}"
    protocol        = "tcp"
    security_groups = ["${aws_security_group.internal_lb_sg.id}"]
    description     = "${local.common_name}-instance-internal-sg"
  }

  ingress {
    from_port       = "${var.alb_http_port}"
    to_port         = "${var.alb_http_port}"
    protocol        = "tcp"
    security_groups = ["${aws_security_group.internal_lb_sg.id}"]
    description     = "${local.common_name}-instance-internal-sg"
  }

  egress {
    from_port = "5432"
    to_port   = "5432"
    protocol  = "tcp"

    cidr_blocks = ["${local.db_cidr_block}"]

    description = "${local.common_name}-rds-sg"
  }

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = -1
    self      = true
  }

  tags = "${merge(local.tags, map("Name", "${local.common_name}-instance-internal-sg"))}"
}

#-------------------------------------------------------------
### rds sg
#-------------------------------------------------------------
resource "aws_security_group" "rds_sg" {
  name        = "${local.common_name}-sg"
  description = "security group for ${local.common_name}-rds-sg"
  vpc_id      = "${local.vpc_id}"

  ingress {
    from_port = "5432"
    to_port   = "5432"
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.internal_instance.id}",
    ]

    description = "${local.common_name}-rds-sg"
  }

  tags = "${merge(local.tags, map("Name", "${local.common_name}-rds-sg"))}"
}
