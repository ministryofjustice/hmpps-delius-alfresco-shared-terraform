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

# Snapshot Role
resource "aws_iam_role" "elasticsearch" {
  name = "${local.common_name}-elasticsearch-role"
  assume_role_policy = templatefile(
    "${path.module}/./policies/es_assume.json",
    {}
  )
  description = "${local.common_name}-snapshot-role"
  tags        = local.tags
}

module "create-snapshot-policy-es" {
  source = "../modules/iam/rolepolicy"
  policyfile = templatefile(
    "${path.module}/./policies/snapshotRole.json",
    {
      bucket_arn = local.elk_backups_bucket_arn
      domain_arn = aws_elasticsearch_domain.es.arn
      kms_arn    = local.storage_kms_arn
    }
  )
  rolename = aws_iam_role.elasticsearch.name
}

module "es-lambda" {
  source     = "../modules/iam_role"
  rolename   = "${local.common_name}-lambda"
  policyfile = "lambda.json"
}

module "es-lamda-policy" {
  source = "../modules/iam/rolepolicy"
  policyfile = templatefile(
    "${path.module}/./policies/lambdaRole.json",
    {
      role_arn   = aws_iam_role.elasticsearch.arn
      domain_arn = aws_elasticsearch_domain.es.arn
    }
  )
  rolename = module.es-lambda.iamrole_name
}
