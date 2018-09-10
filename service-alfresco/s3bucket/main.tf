####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

####################################################
# Locals
####################################################

locals {
  common_name = "${var.environment_identifier}-${var.alfresco_app_name}"
  tags        = "${var.tags}"
}

############################################
# KMS KEY GENERATION - FOR ENCRYPTION
############################################

module "kms_key" {
  source       = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//kms"
  kms_key_name = "${local.common_name}"
  tags         = "${local.tags}"
}

############################################
# S3 Buckets
############################################

# #-------------------------------------------
# ### S3 bucket for storage
# #--------------------------------------------
module "s3bucket" {
  source            = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//s3bucket//s3bucket_logging_encryption"
  s3_bucket_name    = "${local.common_name}-storage"
  kms_master_key_id = "${module.kms_key.kms_key_id}"
  target_bucket     = "${module.s3bucket-logs.s3_bucket_name}"
  tags              = "${local.tags}"
}

# #-------------------------------------------
# ### S3 bucket for logs
# #--------------------------------------------

module "s3bucket-logs" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//s3bucket//s3bucket_without_policy"
  s3_bucket_name = "${local.common_name}-logs"
  acl            = "log-delivery-write"
  tags           = "${local.tags}"
}

# #-------------------------------------------
# ### S3 bucket for cloudtrail
# #--------------------------------------------
module "s3cloudtrail_bucket" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//s3bucket//s3bucket_without_policy"
  s3_bucket_name = "${local.common_name}-cloudtrail"
  tags           = "${local.tags}"
}

#-------------------------------------------
### Attaching S3 bucket policy to cloudtrail bucket
#--------------------------------------------

data "template_file" "s3cloudtrail_policy" {
  template = "${var.s3cloudtrail_policy_file}"

  vars {
    s3_bucket_arn = "${module.s3cloudtrail_bucket.s3_bucket_arn}"
  }
}

module "s3cloudtrail_policy" {
  source       = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//s3bucket//s3bucket_policy"
  s3_bucket_id = "${module.s3cloudtrail_bucket.s3_bucket_name}"
  policyfile   = "${data.template_file.s3cloudtrail_policy.rendered}"
}

############################################
# CloudTrail
############################################
module "cloudtrail" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//cloudtrail//s3bucket"
  s3_bucket_name = "${module.s3cloudtrail_bucket.s3_bucket_name}"
  cloudtrailname = "${local.common_name}"
  globalevents   = false
  multiregion    = false
  s3_bucket_arn  = "${module.s3bucket.s3_bucket_arn}"
  tags           = "${local.tags}"
}
