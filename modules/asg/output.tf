# ELB
output "asg_elb_id" {
  description = "The name of the ELB"
  value       = "${aws_lb.environment.id}"
}

output "asg_elb_name" {
  description = "The name of the ELB"
  value       = "${aws_lb.environment.dns_name}"
}

output "asg_elb_dns_name" {
  description = "The DNS name of the ELB"
  value       = "${aws_lb.environment.dns_name}"
}


output "asg_elb_zone_id" {
  description = "The canonical hosted zone ID of the ELB (to be used in a Route 53 Alias record)"
  value       = "${aws_lb.environment.zone_id}"
}

output "asg_elb_dns_cname" {
  value = "${aws_route53_record.dns_entry.fqdn}"
}

# Launch config
output "asg_launch_id" {
  value = "${aws_launch_configuration.environment.id}"
}

output "asg_launch_name" {
  value = "${aws_launch_configuration.environment.name}"
}

# ASG
output "asg_autoscale_id" {
  value = "${aws_autoscaling_group.environment.id}"
}

output "asg_autoscale_arn" {
  value = "${aws_autoscaling_group.environment.arn}"
}

output "asg_autoscale_name" {
  value = "${aws_autoscaling_group.environment.name}"
}

# LOG GROUPS
output "asg_loggroup_arn" {
  value = "${module.create_loggroup.loggroup_arn}"
}

output "asg_loggroup_name" {
  value = "${module.create_loggroup.loggroup_name}"
}

# AMI
output "asg_latest_ami" {
  value = "${var.ami_id}"
}
