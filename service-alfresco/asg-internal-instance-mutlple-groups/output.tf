# ELB
output "service_alfresco_asg_internal_instance_mutlple_groups_elb_id" {
  description = "The name of the ELB"
  value       = "${module.create_app_elb.environment_elb_id}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_elb_name" {
  description = "The name of the ELB"
  value       = "${module.create_app_elb.environment_elb_name}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_elb_dns_name" {
  description = "The DNS name of the ELB"
  value       = "${module.create_app_elb.environment_elb_dns_name}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_elb_instances" {
  description = "The list of instances in the ELB (if may be outdated, because instances are attached using elb_attachment resource)"
  value       = ["${module.create_app_elb.environment_elb_instances}"]
}

output "service_alfresco_asg_internal_instance_mutlple_groups_elb_source_security_group_id" {
  description = "The ID of the security group that you can use as part of your inbound rules for your load balancer's back-end application instances"
  value       = "${module.create_app_elb.environment_elb_source_security_group_id}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_elb_zone_id" {
  description = "The canonical hosted zone ID of the ELB (to be used in a Route 53 Alias record)"
  value       = "${module.create_app_elb.environment_elb_zone_id}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_elb_dns_cname" {
  value = "${local.common_name}.${var.internal_domain}"
}

# Launch config
# AZ1
output "service_alfresco_asg_internal_instance_mutlple_groups_launch_id_az1" {
  value = "${module.launch_cfg_az1.launch_id}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_launch_name_az1" {
  value = "${module.launch_cfg_az1.launch_name}"
}

# AZ2
output "service_alfresco_asg_internal_instance_mutlple_groups_launch_id_az2" {
  value = "${module.launch_cfg_az2.launch_id}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_launch_name_az2" {
  value = "${module.launch_cfg_az2.launch_name}"
}

# AZ3
output "service_alfresco_asg_internal_instance_mutlple_groups_launch_id_az3" {
  value = "${module.launch_cfg_az3.launch_id}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_launch_name_az3" {
  value = "${module.launch_cfg_az3.launch_name}"
}

# ASG
#AZ1
output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_id_az1" {
  value = "${module.auto_scale_az1.autoscale_id}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_arn_az1" {
  value = "${module.auto_scale_az1.autoscale_arn}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_name_az1" {
  value = "${module.auto_scale_az1.autoscale_name}"
}

#AZ2
output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_id_az2" {
  value = "${module.auto_scale_az2.autoscale_id}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_arn_az2" {
  value = "${module.auto_scale_az2.autoscale_arn}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_name_az2" {
  value = "${module.auto_scale_az2.autoscale_name}"
}

#AZ3
output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_id_az3" {
  value = "${module.auto_scale_az3.autoscale_id}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_arn_az3" {
  value = "${module.auto_scale_az3.autoscale_arn}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_name_az3" {
  value = "${module.auto_scale_az3.autoscale_name}"
}

# LOG GROUPS
output "service_alfresco_asg_internal_instance_mutlple_groups_loggroup_arn" {
  value = "${module.create_loggroup.loggroup_arn}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_loggroup_name" {
  value = "${module.create_loggroup.loggroup_name}"
}

# AMI
output "service_alfresco_asg_internal_instance_mutlple_groups_latest_ami" {
  value = "${var.ami_id}"
}
