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
output "log_group" {
  value = "${aws_cloudwatch_log_group.lambda.name}"
}

# lambda
output "lambda_arn" {
  value = "${aws_lambda_function.lambda.arn}"
}

output "lambda_last_modified" {
  value = "${aws_lambda_function.lambda.last_modified}"
}
