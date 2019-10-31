locals {
  ecs_role_policy_file = "${file("./policies/ecs_role_policy.json")}"
  ecs_policy_file      = "ecs_policy.json"
}

#-------------------------------------------------------------
### INTERNAL IAM POLICES FOR ECS SERVICES
#-------------------------------------------------------------

data "template_file" "iam_policy_ecs_int" {
  template = "${local.ecs_role_policy_file}"

  vars {
    aws_lb_arn = "*"
  }
}

module "create-iam-ecs-role-int" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//iam//role"
  rolename   = "${local.common_name}-mig-ecs"
  policyfile = "${local.ecs_policy_file}"
}

module "create-iam-ecs-policy-int" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//iam//rolepolicy"
  policyfile = "${data.template_file.iam_policy_ecs_int.rendered}"
  rolename   = "${module.create-iam-ecs-role-int.iamrole_name}"
}

#-------------------------------------------------------------
### INTERNAL IAM POLICES FOR ECS SERVICES APP
#-------------------------------------------------------------

data "template_file" "es" {
  template = "${file("./policies/es_internal_policy.json")}"

  vars {
    app_role_arn      = "${module.create-iam-app-role-es.iamrole_arn}"
    config_bucket_arn = "${local.config_bucket_arn}"
    elk_bucket_arn    = "${local.elk_bucket_arn}"
    elk_kms_arn       = "${local.elk_kms_arn}"
    storage_kms_arn   = "${local.storage_kms_arn}"
    elk_user_arn      = "${data.aws_ssm_parameter.elk_user.arn}"
    elk_password_arn  = "${data.aws_ssm_parameter.elk_password.arn}"
  }
}

module "create-iam-app-role-es" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//iam//role"
  rolename   = "${local.common_name}-mig-ec2"
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

# ecs execution
data "template_file" "execution_assume" {
  template = "${file("../policies/ecs_assume.json")}"
  vars {}
}
data "template_file" "execution" {
  template = "${file("../policies/execution.json")}"
  vars {}
}

resource "aws_iam_role" "execution" {
  name               = "${local.common_name}-execute-role"
  assume_role_policy = "${data.template_file.execution_assume.rendered}"
  description        = "${local.common_name}-execute-role"
}

resource "aws_iam_role_policy" "execution" {
  name   = "${local.common_name}-execute-pol"
  role   = "${aws_iam_role.execution.name}"
  policy = "${data.template_file.execution.rendered}"
}

# task
resource "aws_iam_role" "task" {
  name               = "${local.common_name}-task-role"
  assume_role_policy = "${data.template_file.execution_assume.rendered}"
  description        = "${local.common_name}-task-role"
}

resource "aws_iam_role_policy" "task" {
  name   = "${local.common_name}-task-pol"
  role   = "${aws_iam_role.task.name}"
  policy = "${data.template_file.es.rendered}"
}
