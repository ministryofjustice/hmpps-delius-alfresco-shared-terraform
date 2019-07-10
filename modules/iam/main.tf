####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

####################################################
# Locals
####################################################
locals {
  common_name                = "${var.common_name}"
  tags                       = "${var.tags}"
  s3-config-bucket           = "${var.s3-config-bucket}"
  remote_iam_role            = "${var.remote_iam_role}"
  remote_config_bucket       = "${var.remote_config_bucket}"
  storage_s3bucket           = "${var.storage_s3bucket}"
  s3bucket_kms_arn           = "${var.s3bucket_kms_arn}"
  restore_dynamodb_table_arn = "${var.restore_dynamodb_table_arn}"
}

############################################
# CREATE IAM POLICIES
############################################
#-------------------------------------------------------------
### EXTERNAL IAM POLICES FOR ECS SERVICES
#-------------------------------------------------------------

data "template_file" "iam_policy_ecs_ext" {
  template = "${var.ecs_role_policy_file}"

  vars {
    aws_lb_arn = "*"
  }
}

module "create-iam-ecs-role-ext" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//iam//role"
  rolename   = "${local.common_name}-ext-ecs-svc"
  policyfile = "${var.ecs_policy_file}"
}

module "create-iam-ecs-policy-ext" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//iam//rolepolicy"
  policyfile = "${data.template_file.iam_policy_ecs_ext.rendered}"
  rolename   = "${module.create-iam-ecs-role-ext.iamrole_name}"
}

#-------------------------------------------------------------
### EXTERNAL IAM POLICES FOR EC2 RUNNING ECS SERVICES
#-------------------------------------------------------------

data "template_file" "iam_policy_app_ext" {
  template = "${file("../policies/ec2_external_policy.json")}"

  vars {
    s3-config-bucket = "${local.s3-config-bucket}"
    app_role_arn     = "${module.create-iam-app-role-ext.iamrole_arn}"
  }
}

module "create-iam-app-role-ext" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//iam//role"
  rolename   = "${local.common_name}-ext-ec2"
  policyfile = "${var.ec2_policy_file}"
}

module "create-iam-instance-profile-ext" {
  source = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//iam//instance_profile"
  role   = "${module.create-iam-app-role-ext.iamrole_name}"
}

module "create-iam-app-policy-ext" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//iam//rolepolicy"
  policyfile = "${data.template_file.iam_policy_app_ext.rendered}"
  rolename   = "${module.create-iam-app-role-ext.iamrole_name}"
}

#-------------------------------------------------------------
### INTERNAL IAM POLICES FOR EC2 RUNNING ECS SERVICES
#-------------------------------------------------------------

data "template_file" "iam_policy_app_int" {
  template = "${var.ec2_internal_policy_file}"

  vars {
    s3-config-bucket           = "${local.s3-config-bucket}"
    app_role_arn               = "${module.create-iam-app-role-int.iamrole_arn}"
    remote_iam_role            = "${local.remote_iam_role}"
    remote_config_bucket       = "${local.remote_config_bucket}"
    storage_s3bucket           = "${local.storage_s3bucket}"
    s3bucket_kms_arn           = "${local.s3bucket_kms_arn}"
    restore_dynamodb_table_arn = "${local.restore_dynamodb_table_arn}"
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
