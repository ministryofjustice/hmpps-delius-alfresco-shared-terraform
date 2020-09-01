#-------------------------------------------------------------
### INTERNAL IAM POLICES FOR ECS SERVICES APP
#-------------------------------------------------------------

data "template_file" "es" {
  template = file("../policies/es_admin_policy.json")

  vars = {
    config-bucket             = local.config-bucket
    app_role_arn              = module.create-iam-app-role-es.iamrole_arn
    alfresco_kms_arn          = local.alfresco_kms_arn
    alfresco-storage_s3bucket = local.alfresco-storage_s3bucket
    monitoring_bucket_arn     = local.monitoring_bucket_arn
    monitoring_kms_arn        = local.monitoring_kms_arn
    alf_backups_bucket_arn    = local.alf_backups_bucket_arn
    artefacts-s3bucket-arn    = local.artefacts-s3bucket-arn
    db_user_name_arn          = data.aws_ssm_parameter.db_user.arn
    db_password_arn           = data.aws_ssm_parameter.db_password.arn
    elk_backups_bucket_arn    = data.terraform_remote_state.s3bucket.outputs.elk_backups_bucket_arn
  }
}

module "create-iam-app-role-es" {
  source     = "../modules/iam_role"
  rolename   = "${local.common_name}-es-admin"
  policyfile = "ec2_lambda.json"
}

module "create-iam-instance-profile-es" {
  source = "../modules/hmpps-terraform-modules/iam/instance_profile"
  role   = module.create-iam-app-role-es.iamrole_name
}

module "create-iam-app-policy-es" {
  source     = "../modules/hmpps-terraform-modules/iam/rolepolicy"
  policyfile = data.template_file.es.rendered
  rolename   = module.create-iam-app-role-es.iamrole_name
}

# backups cross account
# KMS and Bucket name hard coded
data "template_file" "cross_account" {
  template = file("../policies/cross_account_access_backups.json")
  vars = {
    prod_backups_bucket = "tf-eu-west-2-hmpps-delius-prod-alfresco-alf-backups"
    prod_storage_bucket = "tf-eu-west-2-hmpps-delius-prod-alfresco-storage-s3bucket"
    prod_kms_key_arn    = "arn:aws:kms:eu-west-2:050243167760:key/f32be75c-beb8-409c-a970-db9de7201473"
  }
}

resource "aws_iam_policy" "cross_account" {
  name        = "${local.common_name}-es-admin-cross-account"
  count       = var.alf_iam_cross_account_perms
  description = "access backups bucket"
  policy      = data.template_file.cross_account.rendered
}

resource "aws_iam_role_policy_attachment" "cross_account" {
  count      = var.alf_iam_cross_account_perms
  role       = module.create-iam-app-role-es.iamrole_name
  policy_arn = aws_iam_policy.cross_account[0].arn
}

