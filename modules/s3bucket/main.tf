####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

####################################################
# Locals
####################################################

locals {
  common_name = var.common_name
  tags        = var.tags
}

############################################
# KMS KEY GENERATION - FOR ENCRYPTION
############################################

module "kms_key" {
  source              = "../kms"
  kms_key_name        = local.common_name
  kms_policy_template = var.kms_policy_template
  tags                = local.tags
}

############################################
# S3 Buckets
############################################

# #-------------------------------------------
# ### S3 bucket for storage
# #--------------------------------------------
module "s3bucket" {
  source              = "../s3bucket_logging_encryption"
  s3_bucket_name      = "${local.common_name}-storage"
  kms_master_key_id   = module.kms_key.kms_key_id
  target_bucket       = module.s3bucket-logs.s3_bucket_name
  versioning          = true
  tags                = local.tags
  s3_lifecycle_config = var.s3_lifecycle_config
}

# #-------------------------------------------
# ### S3 bucket for logs
# #--------------------------------------------

module "s3bucket-logs" {
  source         = "../hmpps-terraform-modules/s3bucket/s3bucket_without_policy"
  s3_bucket_name = "${local.common_name}-logs"
  acl            = "log-delivery-write"
  tags           = local.tags
}

# #-------------------------------------------
# ### S3 bucket for cloudtrail
# #--------------------------------------------
module "s3cloudtrail_bucket" {
  source         = "../hmpps-terraform-modules/s3bucket/s3bucket_without_policy"
  s3_bucket_name = "${local.common_name}-cloudtrail"
  tags           = local.tags
}

#-------------------------------------------
### Attaching S3 bucket policy to cloudtrail bucket
#--------------------------------------------

data "template_file" "s3cloudtrail_policy" {
  template = var.s3cloudtrail_policy_file

  vars = {
    s3_bucket_arn = module.s3cloudtrail_bucket.s3_bucket_arn
  }
}

module "s3cloudtrail_policy" {
  source       = "../hmpps-terraform-modules/s3bucket/s3bucket_policy"
  s3_bucket_id = module.s3cloudtrail_bucket.s3_bucket_name
  policyfile   = data.template_file.s3cloudtrail_policy.rendered
}

############################################
# CloudTrail
############################################
module "cloudtrail" {
  source         = "../hmpps-terraform-modules/cloudtrail/s3bucket"
  s3_bucket_name = module.s3cloudtrail_bucket.s3_bucket_name
  cloudtrailname = local.common_name
  globalevents   = false
  multiregion    = false
  s3_bucket_arn  = module.s3bucket.s3_bucket_arn
  tags           = local.tags
}

