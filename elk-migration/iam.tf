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
    app_role_arn = "${module.create-iam-app-role-es.iamrole_arn}"
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
