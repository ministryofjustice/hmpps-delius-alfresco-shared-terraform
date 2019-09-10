# ELB
output "asg_elb_id" {
  description = "The name of the ELB"
  value       = "${module.create_app_elb.environment_elb_id}"
}

output "asg_elb_name" {
  description = "The name of the ELB"
  value       = "${module.create_app_elb.environment_elb_name}"
}

output "asg_elb_dns_name" {
  description = "The DNS name of the ELB"
  value       = "${module.create_app_elb.environment_elb_dns_name}"
}

output "asg_elb_instances" {
  description = "The list of instances in the ELB (if may be outdated, because instances are attached using elb_attachment resource)"
  value       = ["${module.create_app_elb.environment_elb_instances}"]
}

output "asg_elb_source_security_group_id" {
  description = "The ID of the security group that you can use as part of your inbound rules for your load balancer's back-end application instances"
  value       = "${module.create_app_elb.environment_elb_source_security_group_id}"
}

output "asg_elb_zone_id" {
  description = "The canonical hosted zone ID of the ELB (to be used in a Route 53 Alias record)"
  value       = "${module.create_app_elb.environment_elb_zone_id}"
}

output "asg_elb_dns_cname" {
  value = "${aws_route53_record.dns_entry.fqdn}"
}

# Launch config
output "asg_launch_id" {
  value = "${module.launch_cfg.launch_id}"
}

output "asg_launch_name" {
  value = "${module.launch_cfg.launch_name}"
}

# ASG
output "asg_autoscale_id" {
  value = "${module.auto_scale.autoscale_id}"
}

output "asg_autoscale_arn" {
  value = "${module.auto_scale.autoscale_arn}"
}

output "asg_autoscale_name" {
  value = "${module.auto_scale.autoscale_name}"
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
