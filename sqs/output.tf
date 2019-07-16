# backups queue
output "backups_queue_id" {
  value = "${aws_sqs_queue.alf_queue.id}"
}

output "backups_queue_arn" {
  value = "${aws_sqs_queue.alf_queue.arn}"
}
