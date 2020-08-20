output "target_group_id" {
  value = aws_lb_target_group.environment.id
}

output "target_group_arn" {
  value = aws_lb_target_group.environment.arn
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.environment.arn_suffix
}

output "target_group_name" {
  value = aws_lb_target_group.environment.name
}

