####################################################
# Common
####################################################
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
# Route53
output "common_private_zone_id" {
  value = "${module.common.common_private_zone_id}"
}

output "common_private_zone_name" {
  value = "${module.common.common_private_zone_name}"
}

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
output "service_alfresco_security_groups_sg_internal_lb_id" {
  value = "${module.security_groups.service_alfresco_security_groups_sg_internal_lb_id}"
}

output "service_alfresco_security_groups_sg_internal_instance_id" {
  value = "${module.security_groups.service_alfresco_security_groups_sg_internal_instance_id}"
}

output "service_alfresco_security_groups_sg_rds_id" {
  value = "${module.security_groups.service_alfresco_security_groups_sg_rds_id}"
}

####################################################
# S3 Buckets - Application specific
####################################################

output "service_alfresco_s3bucket" {
  value = "${module.s3bucket.service_alfresco_s3bucket}"
}

output "service_alfresco_s3bucket-logs" {
  value = "${module.s3bucket.service_alfresco_s3bucket-logs}"
}

# KMS Key
output "service_alfresco_s3bucket_kms_arn" {
  value = "${module.s3bucket.service_alfresco_s3bucket_kms_arn}"
}

output "service_alfresco_s3bucket_kms_id" {
  value = "${module.s3bucket.service_alfresco_s3bucket_kms_id}"
}

# cloudtrail
output "service_alfresco_s3bucket_cloudtrail_arn" {
  value = "${module.s3bucket.service_alfresco_s3bucket_cloudtrail_arn}"
}

output "service_alfresco_s3bucket_cloudtrail_id" {
  value = "${module.s3bucket.service_alfresco_s3bucket_cloudtrail_id}"
}

####################################################
# IAM - Application specific
####################################################
# INTERNAL

# APP ROLE
output "service_alfresco_iam_policy_int_app_role_name" {
  value = "${module.iam.service_alfresco_iam_policy_int_app_role_name}"
}

output "service_alfresco_iam_policy_int_app_role_arn" {
  value = "${module.iam.service_alfresco_iam_policy_int_app_role_arn}"
}

# PROFILE
output "service_alfresco_iam_policy_int_app_instance_profile_name" {
  value = "${module.iam.service_alfresco_iam_policy_int_app_instance_profile_name}"
}

####################################################
# RDS - Application specific
####################################################
# KMS Key
output "service_alfresco_rds_kms_arn" {
  value = "${module.rds.service_alfresco_rds_kms_arn}"
}

output "service_alfresco_rds_kms_id" {
  value = "${module.rds.service_alfresco_rds_kms_id}"
}

# IAM
output "service_alfresco_rds_monitoring_role_arn" {
  value = "${module.rds.service_alfresco_rds_monitoring_role_arn}"
}

output "service_alfresco_rds_monitoring_role_name" {
  value = "${module.rds.service_alfresco_rds_monitoring_role_name}"
}

# DB SUBNET GROUP
output "service_alfresco_rds_db_subnet_group_id" {
  value = "${module.rds.service_alfresco_rds_db_subnet_group_id}"
}

output "service_alfresco_rds_db_subnet_group_arn" {
  value = "${module.rds.service_alfresco_rds_db_subnet_group_arn}"
}

# PARAMETER GROUP
output "service_alfresco_rds_parameter_group_id" {
  value = "${module.rds.service_alfresco_rds_parameter_group_id}"
}

output "service_alfresco_rds_parameter_group_arn" {
  value = "${module.rds.service_alfresco_rds_parameter_group_arn}"
}

# DB OPTIONS GROUP
output "service_alfresco_rds_db_option_group_id" {
  value = "${module.rds.service_alfresco_rds_db_option_group_id}"
}

output "service_alfresco_rds_db_option_group_arn" {
  value = "${module.rds.service_alfresco_rds_db_option_group_arn}"
}

# DB INSTANCE
output "service_alfresco_rds_db_instance_address" {
  description = "The address of the RDS instance"
  value       = "${module.rds.service_alfresco_rds_db_instance_address}"
}

output "service_alfresco_rds_db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = "${module.rds.service_alfresco_rds_db_instance_arn}"
}

output "service_alfresco_rds_db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = "${module.rds.service_alfresco_rds_db_instance_availability_zone}"
}

output "service_alfresco_rds_db_instance_endpoint" {
  description = "The connection endpoint"
  value       = "${module.rds.service_alfresco_rds_db_instance_endpoint}"
}

output "service_alfresco_rds_db_instance_endpoint_cname" {
  description = "The connection endpoint"
  value       = "${module.rds.service_alfresco_rds_db_instance_endpoint_cname}"
}

output "service_alfresco_rds_db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = "${module.rds.service_alfresco_rds_db_instance_hosted_zone_id}"
}

output "service_alfresco_rds_db_instance_id" {
  description = "The RDS instance ID"
  value       = "${module.rds.service_alfresco_rds_db_instance_id}"
}

output "service_alfresco_rds_db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = "${module.rds.service_alfresco_rds_db_instance_resource_id}"
}

output "service_alfresco_rds_db_instance_status" {
  description = "The RDS instance status"
  value       = "${module.rds.service_alfresco_rds_db_instance_status}"
}

output "service_alfresco_rds_db_instance_database_name" {
  description = "The database name"
  value       = "${module.rds.service_alfresco_rds_db_instance_database_name}"
}

output "service_alfresco_rds_db_instance_username" {
  description = "The master username for the database"
  value       = "${module.rds.service_alfresco_rds_db_instance_username}"
}

output "service_alfresco_rds_db_instance_port" {
  description = "The database port"
  value       = "${module.rds.service_alfresco_rds_db_instance_port}"
}

####################################################
# ASG - Application specific
####################################################
# ELB
output "service_alfresco_asg_internal_instance_mutlple_groups_elb_id" {
  description = "The name of the ELB"
  value       = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_elb_id}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_elb_name" {
  description = "The name of the ELB"
  value       = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_elb_name}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_elb_dns_name" {
  description = "The DNS name of the ELB"
  value       = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_elb_dns_name}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_elb_instances" {
  description = "The list of instances in the ELB (if may be outdated, because instances are attached using elb_attachment resource)"
  value       = ["${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_elb_instances}"]
}

output "service_alfresco_asg_internal_instance_mutlple_groups_elb_source_security_group_id" {
  description = "The ID of the security group that you can use as part of your inbound rules for your load balancer's back-end application instances"
  value       = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_elb_source_security_group_id}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_elb_zone_id" {
  description = "The canonical hosted zone ID of the ELB (to be used in a Route 53 Alias record)"
  value       = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_elb_zone_id}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_elb_dns_cname" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_elb_dns_cname}"
}

# Launch config
# AZ1
output "service_alfresco_asg_internal_instance_mutlple_groups_launch_id_az1" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_launch_id_az1}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_launch_name_az1" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_launch_id_az1}"
}

# AZ2
output "service_alfresco_asg_internal_instance_mutlple_groups_launch_id_az2" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_launch_id_az2}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_launch_name_az2" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_launch_name_az2}"
}

# AZ3
output "service_alfresco_asg_internal_instance_mutlple_groups_launch_id_az3" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_launch_id_az3}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_launch_name_az3" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_launch_name_az3}"
}

# ASG
#AZ1
output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_id_az1" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_autoscale_id_az1}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_arn_az1" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_autoscale_arn_az1}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_name_az1" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_autoscale_name_az1}"
}

#AZ2
output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_id_az2" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_autoscale_id_az2}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_arn_az2" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_autoscale_arn_az2}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_name_az2" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_autoscale_name_az2}"
}

#AZ3
output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_id_az3" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_autoscale_id_az3}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_arn_az3" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_autoscale_arn_az3}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_autoscale_name_az3" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_autoscale_name_az3}"
}

# LOG GROUPS
output "service_alfresco_asg_internal_instance_mutlple_groups_loggroup_arn" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_loggroup_arn}"
}

output "service_alfresco_asg_internal_instance_mutlple_groups_loggroup_name" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_loggroup_name}"
}

# AMI
output "service_alfresco_asg_internal_instance_mutlple_groups_latest_ami" {
  value = "${module.asg.service_alfresco_asg_internal_instance_mutlple_groups_latest_ami}"
}
