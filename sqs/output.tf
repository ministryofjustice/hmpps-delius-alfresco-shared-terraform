# backups queue
output "backups_queue_id" {
  value = "${aws_sqs_queue.alf_queue.id}"
}

output "backups_queue_arn" {
  value = "${aws_sqs_queue.alf_queue.arn}"
}

output "backup_config" {
  value = {
    queue_name    = "${aws_sqs_queue.alf_queue.id}"
    poll_interval = "${var.alf_sqs_backup_config["poll_interval"]}"
    image         = "${var.alf_sqs_backup_config["image"]}"
  }
}
