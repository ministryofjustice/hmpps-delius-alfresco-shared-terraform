####################################################
# IAM - Application specific
####################################################

#ES-Admin
output "iam_role_name" {
  value = "${aws_iam_role.lambda.name}"
}

output "iam_role_arn" {
  value = "${aws_iam_role.lambda.arn}"
}

# logs
output "alf_log_group" {
  value = "${aws_cloudwatch_log_group.alf_lambda.name}"
}

output "elk_log_group" {
  value = "${aws_cloudwatch_log_group.elk_lambda.name}"
}
# lambda
output "alf_lambda_arn" {
  value = "${aws_lambda_function.alf_lambda.arn}"
}

output "alf_lambda_last_modified" {
  value = "${aws_lambda_function.alf_lambda.last_modified}"
}


output "elk_lambda_arn" {
  value = "${aws_lambda_function.elk_lambda.arn}"
}

output "elk_lambda_last_modified" {
  value = "${aws_lambda_function.elk_lambda.last_modified}"
}
