# LB
output "lb_id" {
  value = "${module.create_app_elb.environment_elb_id}"
}

output "lb_arn" {
  value = "${module.create_app_elb.environment_elb_arn}"
}

output "lb_dns_name" {
  value = "${module.create_app_elb.environment_elb_dns_name}"
}

output "lb_dns_alias" {
  value = "${aws_route53_record.dns_entry.fqdn}"
}

output "lb_zone_id" {
  value = "${module.create_app_elb.environment_elb_zone_id}"
}

# LOG GROUPS
output "loggroup_arn" {
  value = "${module.create_loggroup.loggroup_arn}"
}

output "loggroup_name" {
  value = "${module.create_loggroup.loggroup_name}"
}

# Launch config
output "launch_id" {
  value = "${module.launch_cfg.launch_id}"
}

output "launch_name" {
  value = "${module.launch_cfg.launch_name}"
}

# ASG
output "autoscale_id" {
  value = "${module.auto_scale.autoscale_id}"
}

output "autoscale_arn" {
  value = "${module.auto_scale.autoscale_arn}"
}

output "autoscale_name" {
  value = "${module.auto_scale.autoscale_name}"
}
