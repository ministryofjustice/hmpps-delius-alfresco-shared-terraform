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
    backups_dynamodb_table_arn = "${local.backups_dynamodb_table_arn}"
    monitoring_bucket_arn      = "${local.monitoring_bucket_arn}"
    monitoring_kms_arn         = "${local.monitoring_kms_arn}"
    alf_backups_bucket_arn     = "${local.alf_backups_bucket_arn}"
    artefacts-s3bucket-arn     = "${local.artefacts-s3bucket-arn}"
    db_user_name_arn           = "${data.aws_ssm_parameter.db_user.arn}"
    db_password_arn            = "${data.aws_ssm_parameter.db_password.arn}"
    tls_key_arn                = "${data.aws_ssm_parameter.tls_key.arn}"
    tls_cert_arn               = "${data.aws_ssm_parameter.tls_cert.arn}"
    tls_ca_cert_arn            = "${data.aws_ssm_parameter.tls_ca_cert.arn}"
    elk_backups_bucket_arn     = "${data.terraform_remote_state.s3bucket.elk_backups_bucket_arn}"
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
