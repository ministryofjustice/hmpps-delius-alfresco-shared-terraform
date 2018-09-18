####################################################
# ASG - Application specific
####################################################
# ELB
output "asg_elb_id" {
  description = "The name of the ELB"
  value       = "${module.asg.asg_elb_id}"
}

output "asg_elb_name" {
  description = "The name of the ELB"
  value       = "${module.asg.asg_elb_name}"
}

output "asg_elb_dns_name" {
  description = "The DNS name of the ELB"
  value       = "${module.asg.asg_elb_dns_name}"
}

output "asg_elb_instances" {
  description = "The list of instances in the ELB (if may be outdated, because instances are attached using elb_attachment resource)"
  value       = ["${module.asg.asg_elb_instances}"]
}

output "asg_elb_source_security_group_id" {
  description = "The ID of the security group that you can use as part of your inbound rules for your load balancer's back-end application instances"
  value       = "${module.asg.asg_elb_source_security_group_id}"
}

output "asg_elb_dns_cname" {
  value = "${module.asg.asg_elb_dns_cname}"
}

output "asg_elb_dns_cname_private" {
  value = "${module.asg.asg_elb_dns_cname_private}"
}

# Launch config
# AZ1
output "asg_launch_id_az1" {
  value = "${module.asg.asg_launch_id_az1}"
}

output "asg_launch_name_az1" {
  value = "${module.asg.asg_launch_id_az1}"
}

# AZ2
output "asg_launch_id_az2" {
  value = "${module.asg.asg_launch_id_az2}"
}

output "asg_launch_name_az2" {
  value = "${module.asg.asg_launch_name_az2}"
}

# AZ3
output "asg_launch_id_az3" {
  value = "${module.asg.asg_launch_id_az3}"
}

output "asg_launch_name_az3" {
  value = "${module.asg.asg_launch_name_az3}"
}

# ASG
#AZ1
output "asg_autoscale_id_az1" {
  value = "${module.asg.asg_autoscale_id_az1}"
}

output "asg_autoscale_arn_az1" {
  value = "${module.asg.asg_autoscale_arn_az1}"
}

output "asg_autoscale_name_az1" {
  value = "${module.asg.asg_autoscale_name_az1}"
}

#AZ2
output "asg_autoscale_id_az2" {
  value = "${module.asg.asg_autoscale_id_az2}"
}

output "asg_autoscale_arn_az2" {
  value = "${module.asg.asg_autoscale_arn_az2}"
}

output "asg_autoscale_name_az2" {
  value = "${module.asg.asg_autoscale_name_az2}"
}

#AZ3
output "asg_autoscale_id_az3" {
  value = "${module.asg.asg_autoscale_id_az3}"
}

output "asg_autoscale_arn_az3" {
  value = "${module.asg.asg_autoscale_arn_az3}"
}

output "asg_autoscale_name_az3" {
  value = "${module.asg.asg_autoscale_name_az3}"
}

# LOG GROUPS
output "asg_loggroup_arn" {
  value = "${module.asg.asg_loggroup_arn}"
}

output "asg_loggroup_name" {
  value = "${module.asg.asg_loggroup_name}"
}

# AMI
output "asg_latest_ami" {
  value = "${module.asg.asg_latest_ami}"
}
