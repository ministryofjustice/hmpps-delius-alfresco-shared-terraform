resource "aws_iam_role" "environment" {
  name               = "${var.rolename}-role"
  assume_role_policy = "${file("${path.module}/policies/${var.policyfile}")}"
  description        = "${var.rolename}"
}
