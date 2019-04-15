output "dynamodb_table_name" {
  value = "${module.dynamodb-table.aws_dynamodb_table_name}"
}

output "dynamodb_table_arn" {
  value = "${module.dynamodb-table.aws_dynamodb_table_arn}"
}
