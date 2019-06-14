#-------------------------------------------------------------
### INTERNAL IAM POLICES FOR ECS SERVICES APP
#-------------------------------------------------------------

data "template_file" "es" {
  template = "${file("../policies/es_admin_policy.json")}"

  vars {
    config-bucket              = "${local.config-bucket}"
    app_role_arn               = "${module.create-iam-app-role-es.iamrole_arn}"
    alfresco_kms_arn           = "${local.alfresco_kms_arn}"
    alfresco-storage_s3bucket  = "${local.alfresco-storage_s3bucket}"
    restore_dynamodb_table_arn = "${local.restore_dynamodb_table_arn}"
    monitoring_bucket_arn      = "${local.monitoring_bucket_arn}"
    monitoring_kms_arn         = "${local.monitoring_kms_arn}"
  }
}

module "create-iam-app-role-es" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//iam//role"
  rolename   = "${local.common_name}-es-admin"
  policyfile = "ec2_policy.json"
}

module "create-iam-instance-profile-es" {
  source = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//iam//instance_profile"
  role   = "${module.create-iam-app-role-es.iamrole_name}"
}

module "create-iam-app-policy-es" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//iam//rolepolicy"
  policyfile = "${data.template_file.es.rendered}"
  rolename   = "${module.create-iam-app-role-es.iamrole_name}"
}
