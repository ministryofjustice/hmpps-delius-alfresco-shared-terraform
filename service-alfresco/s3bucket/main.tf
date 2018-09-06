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

####################################################
# Locals
####################################################

locals {
  tags = "${data.terraform_remote_state.common.common_tags}"
}

############################################
# KMS KEY GENERATION - FOR ENCRYPTION
############################################

module "kms_key" {
  source       = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//kms"
  kms_key_name = "${var.environment_identifier}-${var.alfresco_app_name}"
  tags         = "${local.tags}"
}

############################################
# S3 Buckets
############################################

# #-------------------------------------------
# ### S3 bucket for storage
# #--------------------------------------------
module "s3bucket" {
  source            = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//s3bucket//s3bucket_logging_encryption"
  s3_bucket_name    = "${var.environment_identifier}-${var.alfresco_app_name}-storage"
  kms_master_key_id = "${module.kms_key.kms_key_id}"
  target_bucket     = "${module.s3bucket-logs.s3_bucket_name}"
  tags              = "${local.tags}"
}

# #-------------------------------------------
# ### S3 bucket for logs
# #--------------------------------------------

module "s3bucket-logs" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//s3bucket//s3bucket_without_policy"
  s3_bucket_name = "${var.environment_identifier}-${var.alfresco_app_name}-logs"
  acl            = "log-delivery-write"
  tags           = "${local.tags}"
}

# #-------------------------------------------
# ### S3 bucket for cloudtrail
# #--------------------------------------------
module "s3cloudtrail_bucket" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//s3bucket//s3bucket_without_policy"
  s3_bucket_name = "${var.environment_identifier}-${var.alfresco_app_name}-cloudtrail"
  tags           = "${local.tags}"
}

#-------------------------------------------
### Attaching S3 bucket policy to cloudtrail bucket
#--------------------------------------------

data "template_file" "s3cloudtrail_policy" {
  template = "${file("policies/s3_cloudtrail_policy.json")}"

  vars {
    s3_bucket_arn = "${module.s3cloudtrail_bucket.s3_bucket_arn}"
  }
}

module "s3cloudtrail_policy" {
  source       = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//s3bucket//s3bucket_policy"
  s3_bucket_id = "${module.s3cloudtrail_bucket.s3_bucket_name}"
  policyfile   = "${data.template_file.s3cloudtrail_policy.rendered}"
}

############################################
# CloudTrail
############################################
module "cloudtrail" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//cloudtrail//s3bucket"
  s3_bucket_name = "${module.s3cloudtrail_bucket.s3_bucket_name}"
  cloudtrailname = "${var.environment_identifier}-${var.alfresco_app_name}"
  globalevents   = false
  multiregion    = false
  s3_bucket_arn  = "${module.s3bucket.s3_bucket_arn}"
  tags           = "${local.tags}"
}
