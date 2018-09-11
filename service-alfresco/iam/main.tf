####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

####################################################
# Locals
####################################################
locals {
  common_name          = "${var.environment_identifier}-${var.alfresco_app_name}"
  tags                 = "${var.tags}"
  s3-config-bucket     = "${var.s3-config-bucket}"
  aws_ecr_arn          = "${var.aws_ecr_arn}"
  remote_iam_role      = "${var.remote_iam_role}"
  remote_config_bucket = "${var.remote_config_bucket}"
  storage_s3bucket     = "${var.storage_s3bucket}"
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
    s3-config-bucket     = "${local.s3-config-bucket}"
    app_role_arn         = "${module.create-iam-app-role-int.iamrole_arn}"
    aws_ecr_arn          = "${local.aws_ecr_arn}"
    remote_iam_role      = "${local.remote_iam_role}"
    remote_config_bucket = "${local.remote_config_bucket}"
    storage_s3bucket     = "${local.storage_s3bucket}"
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
