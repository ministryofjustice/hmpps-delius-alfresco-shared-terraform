output "loggroup_arn" {
  value = aws_cloudwatch_log_group.environment.arn
}

output "loggroup_name" {
  value = aws_cloudwatch_log_group.environment.name
}

