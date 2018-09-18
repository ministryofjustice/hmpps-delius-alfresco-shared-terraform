####################################################
# Common
####################################################
output "region" {
  value = "${data.aws_region.current.name}"
}

output "common_account_id" {
  value = "${module.common.common_account_id}"
}

output "common_role_arn" {
  value = "${module.common.common_role_arn}"
}

output "common_sg_outbound_id" {
  value = "${module.common.common_sg_outbound_id}"
}

# S3 Buckets
output "common_s3-config-bucket" {
  value = "${module.common.common_s3-config-bucket}"
}

output "common_s3_lb_logs_bucket" {
  value = "${module.common.common_s3_lb_logs_bucket}"
}

# SSH KEY
output "common_ssh_deployer_key" {
  value = "${module.common.common_ssh_deployer_key}"
}

## AWS PARAMETER STORE
output "common_ssm_ssh_private_key_name" {
  value = "${module.common.common_ssm_ssh_private_key_name}"
}

output "common_ssm_ssh_public_key_name" {
  value = "${module.common.common_ssm_ssh_public_key_name}"
}

# ENVIRONMENTS SETTINGS
# tags
output "common_tags" {
  value = "${local.tags}"
}

####################################################
# Self Signed CA
####################################################
# key
output "self_signed_ca_private_key" {
  value     = "${module.self_signed_ca.self_signed_ca_private_key}"
  sensitive = true
}

# ca cert
output "self_signed_ca_cert_pem" {
  value = "${module.self_signed_ca.self_signed_ca_cert_pem}"
}

## AWS PARAMETER STORE
output "self_signed_ca_ssm_cert_pem_name" {
  value = "${module.self_signed_ca.self_signed_ca_ssm_cert_pem_name}"
}

####################################################
# Self Signed Cert
####################################################
# key
output "self_signed_server_private_key" {
  value     = "${module.self_signed_cert.self_signed_server_private_key}"
  sensitive = true
}

# csr
output "self_signed_server_cert_request_pem" {
  value     = "${module.self_signed_cert.self_signed_server_cert_request_pem}"
  sensitive = true
}

# cert
output "self_signed_server_cert_pem" {
  value = "${module.self_signed_cert.self_signed_server_cert_pem}"
}

# iam server cert
output "self_signed_server_iam_server_certificate_name" {
  value = "${module.self_signed_cert.self_signed_server_iam_server_certificate_name}"
}

output "self_signed_server_iam_server_certificate_id" {
  value = "${module.self_signed_cert.self_signed_server_iam_server_certificate_id}"
}

output "self_signed_server_iam_server_certificate_arn" {
  value = "${module.self_signed_cert.self_signed_server_iam_server_certificate_arn}"
}

output "self_signed_server_iam_server_certificate_path" {
  value = "${module.self_signed_cert.self_signed_server_iam_server_certificate_path}"
}

## AWS PARAMETER STORE
output "self_signed_server_ssm_cert_pem_name" {
  value = "${module.self_signed_cert.self_signed_server_ssm_cert_pem_name}"
}

output "self_signed_server_ssm_private_key_name" {
  value = "${module.self_signed_cert.self_signed_server_ssm_private_key_name}"
}

####################################################
# SECURITY GROUPS - Application specific
####################################################
output "security_groups_sg_internal_lb_id" {
  value = "${module.security_groups.security_groups_sg_internal_lb_id}"
}

output "security_groups_sg_internal_instance_id" {
  value = "${module.security_groups.security_groups_sg_internal_instance_id}"
}

output "security_groups_sg_rds_id" {
  value = "${module.security_groups.security_groups_sg_rds_id}"
}

####################################################
# S3 Buckets - Application specific
####################################################

output "s3bucket" {
  value = "${module.s3bucket.s3bucket}"
}

output "s3bucket-logs" {
  value = "${module.s3bucket.s3bucket-logs}"
}

# KMS Key
output "s3bucket_kms_arn" {
  value = "${module.s3bucket.s3bucket_kms_arn}"
}

output "s3bucket_kms_id" {
  value = "${module.s3bucket.s3bucket_kms_id}"
}

# cloudtrail
output "s3bucket_cloudtrail_arn" {
  value = "${module.s3bucket.s3bucket_cloudtrail_arn}"
}

output "s3bucket_cloudtrail_id" {
  value = "${module.s3bucket.s3bucket_cloudtrail_id}"
}

####################################################
# IAM - Application specific
####################################################
# INTERNAL

# APP ROLE
output "iam_policy_int_app_role_name" {
  value = "${module.iam.iam_policy_int_app_role_name}"
}

output "iam_policy_int_app_role_arn" {
  value = "${module.iam.iam_policy_int_app_role_arn}"
}

# PROFILE
output "iam_policy_int_app_instance_profile_name" {
  value = "${module.iam.iam_policy_int_app_instance_profile_name}"
}

####################################################
# RDS - Application specific
####################################################
# KMS Key
output "rds_kms_arn" {
  value = "${module.rds.rds_kms_arn}"
}

output "rds_kms_id" {
  value = "${module.rds.rds_kms_id}"
}

# IAM
output "rds_monitoring_role_arn" {
  value = "${module.rds.rds_monitoring_role_arn}"
}

output "rds_monitoring_role_name" {
  value = "${module.rds.rds_monitoring_role_name}"
}

# DB SUBNET GROUP
output "rds_db_subnet_group_id" {
  value = "${module.rds.rds_db_subnet_group_id}"
}

output "rds_db_subnet_group_arn" {
  value = "${module.rds.rds_db_subnet_group_arn}"
}

# PARAMETER GROUP
output "rds_parameter_group_id" {
  value = "${module.rds.rds_parameter_group_id}"
}

output "rds_parameter_group_arn" {
  value = "${module.rds.rds_parameter_group_arn}"
}

# DB OPTIONS GROUP
output "rds_db_option_group_id" {
  value = "${module.rds.rds_db_option_group_id}"
}

output "rds_db_option_group_arn" {
  value = "${module.rds.rds_db_option_group_arn}"
}

# DB INSTANCE
output "rds_db_instance_address" {
  description = "The address of the RDS instance"
  value       = "${module.rds.rds_db_instance_address}"
}

output "rds_db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = "${module.rds.rds_db_instance_arn}"
}

output "rds_db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = "${module.rds.rds_db_instance_availability_zone}"
}

output "rds_db_instance_endpoint" {
  description = "The connection endpoint"
  value       = "${module.rds.rds_db_instance_endpoint}"
}

output "rds_db_instance_endpoint_cname" {
  description = "The connection endpoint"
  value       = "${module.rds.rds_db_instance_endpoint_cname}"
}

output "rds_db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = "${module.rds.rds_db_instance_hosted_zone_id}"
}

output "rds_db_instance_id" {
  description = "The RDS instance ID"
  value       = "${module.rds.rds_db_instance_id}"
}

output "rds_db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = "${module.rds.rds_db_instance_resource_id}"
}

output "rds_db_instance_status" {
  description = "The RDS instance status"
  value       = "${module.rds.rds_db_instance_status}"
}

output "rds_db_instance_database_name" {
  description = "The database name"
  value       = "${module.rds.rds_db_instance_database_name}"
}

output "rds_db_instance_username" {
  description = "The master username for the database"
  value       = "${module.rds.rds_db_instance_username}"
}

output "rds_db_instance_port" {
  description = "The database port"
  value       = "${module.rds.rds_db_instance_port}"
}

output "rds_public_dns_name" {
  value = "${aws_route53_record.rds.name}"
}

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
