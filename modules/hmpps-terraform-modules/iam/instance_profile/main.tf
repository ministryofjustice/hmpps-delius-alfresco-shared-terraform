resource "aws_iam_instance_profile" "environment" {
  name = "${var.role}-instance-profile"
  role = var.role
}

