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

####################################################
# Locals
####################################################

locals {
  region            = "${var.region}"
  alfresco_app_name = "${data.terraform_remote_state.common.alfresco_app_name}"
  common_name       = "${data.terraform_remote_state.common.common_name}"
  tags              = "${data.terraform_remote_state.common.common_tags}"
}

####################################################
# S3 bucket - Application Specific
####################################################
module "s3bucket" {
  source                   = "../modules/s3bucket"
  common_name              = "${local.common_name}"
  tags                     = "${local.tags}"
  s3cloudtrail_policy_file = "${file("../policies/s3bucket/s3_cloudtrail_policy.json")}"
}

#-------------------------------------------
### S3 bucket for elasticsearch
#--------------------------------------------
resource "aws_s3_bucket" "backups" {
  bucket = "${local.common_name}-alf-backups"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    id      = "backups"
    enabled = true

    prefix = "backups/"

    tags = {
      "rule"      = "backups"
      "autoclean" = "true"
    }

    transition {
      days          = 14
      storage_class = "GLACIER"
    }

    expiration {
      days = 2560
    }
  }

  tags = "${merge(local.tags, map("Name", "${local.common_name}-alf-backups"))}"
}
