# ecs execution
data "template_file" "execution_assume" {
  template = file("../policies/ecs_assume.json")
  vars     = {}
}

data "template_file" "execution" {
  template = file("../policies/execution.json")
  vars     = {}
}

resource "aws_iam_role" "execution" {
  name               = "${local.common_name}-execute-role"
  assume_role_policy = data.template_file.execution_assume.rendered
  description        = "${local.common_name}-execute-role"
}

resource "aws_iam_role_policy" "execution" {
  name   = "${local.common_name}-execute-pol"
  role   = aws_iam_role.execution.name
  policy = data.template_file.execution.rendered
}

# task
resource "aws_iam_role" "task" {
  name               = "${local.common_name}-task-role"
  assume_role_policy = data.template_file.execution_assume.rendered
  description        = "${local.common_name}-task-role"
}

resource "aws_iam_role_policy" "task" {
  name = "${local.common_name}-task-pol"
  role = aws_iam_role.task.name
  policy = templatefile(
    "${path.module}/./policies/kibana.json",
    {}
  )
}


module "create-iam-app-role-es" {
  source     = "../modules/iam/role"
  rolename   = "${local.common_name}-inst"
  policyfile = "ec2_policy.json"
}

module "create-iam-instance-profile-es" {
  source = "../modules/iam/instance_profile"
  role   = module.create-iam-app-role-es.iamrole_name
}

module "create-iam-app-policy-es" {
  source = "../modules/iam/rolepolicy"
  policyfile = templatefile(
    "${path.module}/./policies/kibana.json",
    {}
  )
  rolename = module.create-iam-app-role-es.iamrole_name
}
