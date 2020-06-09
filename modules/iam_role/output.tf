output "iamrole_arn" {
  value = "${aws_iam_role.environment.arn}"
}

output "iamrole_id" {
  value = "${aws_iam_role.environment.id}"
}

output "iamrole_name" {
  value = "${aws_iam_role.environment.name}"
}
