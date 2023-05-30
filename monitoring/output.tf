output "db" {
  value = local.db_instance_id
}

output "sns_topic_arn" {
  value = aws_sns_topic.alarm_notification.arn
}