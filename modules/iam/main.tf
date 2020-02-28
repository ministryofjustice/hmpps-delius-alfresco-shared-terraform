####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

####################################################
# Locals
####################################################
locals {
  common_name          = "${var.common_name}"
  tags                 = "${var.tags}"
  s3-config-bucket     = "${var.s3-config-bucket}"
  remote_iam_role      = "${var.remote_iam_role}"
  remote_config_bucket = "${var.remote_config_bucket}"
  storage_s3bucket     = "${var.storage_s3bucket}"
  s3bucket_kms_arn     = "${var.s3bucket_kms_arn}"
}

############################################
# CREATE IAM POLICIES
############################################

#-------------------------------------------------------------
### INTERNAL IAM POLICES FOR EC2 RUNNING ECS SERVICES
#-------------------------------------------------------------

data "template_file" "iam_policy_app_int" {
  template = "${var.ec2_internal_policy_file}"

  vars {
    s3-config-bucket       = "${local.s3-config-bucket}"
    app_role_arn           = "${module.create-iam-app-role-int.iamrole_arn}"
    remote_iam_role        = "${local.remote_iam_role}"
    remote_config_bucket   = "${local.remote_config_bucket}"
    storage_s3bucket       = "${local.storage_s3bucket}"
    s3bucket_kms_arn       = "${local.s3bucket_kms_arn}"
    db_user                = "${var.asg_ssm_arns_map["db_user"]}"
    db_password            = "${var.asg_ssm_arns_map["db_password"]}"
    remote_broker_username = "${var.asg_ssm_arns_map["remote_broker_username"]}"
    remote_broker_password = "${var.asg_ssm_arns_map["remote_broker_password"]}"
    alf_backups_bucket_arn = "${var.alf_backups_bucket_arn}"
  }
}

module "create-iam-app-role-int" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//iam//role"
  rolename   = "${local.common_name}-int-ec2"
  policyfile = "${var.ec2_policy_file}"
}

module "create-iam-instance-profile-int" {
  source = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//iam//instance_profile"
  role   = "${module.create-iam-app-role-int.iamrole_name}"
}

module "create-iam-app-policy-int" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//iam//rolepolicy"
  policyfile = "${data.template_file.iam_policy_app_int.rendered}"
  rolename   = "${module.create-iam-app-role-int.iamrole_name}"
}
