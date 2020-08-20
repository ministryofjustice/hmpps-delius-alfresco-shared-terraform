resource "aws_iam_role_policy" "environment" {
  name   = "${var.rolename}-policy"
  role   = var.rolename
  policy = var.policyfile
}

