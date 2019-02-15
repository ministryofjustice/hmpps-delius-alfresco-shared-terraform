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
  value = "${local.ssh_deployer_key}"
}

# ENVIRONMENTS SETTINGS
# tags
output "common_tags" {
  value = "${local.tags}"
}

# LOCAL OUTPUTS
output "vpc_id" {
  value = "${data.terraform_remote_state.vpc.vpc_id}"
}

output "vpc_cidr_block" {
  value = "${data.terraform_remote_state.vpc.vpc_cidr_block}"
}

output "internal_domain" {
  value = "${data.terraform_remote_state.vpc.private_zone_name}"
}

output "private_zone_id" {
  value = "${data.terraform_remote_state.vpc.private_zone_id}"
}

output "external_domain" {
  value = "${data.terraform_remote_state.vpc.public_zone_name}"
}

output "public_zone_id" {
  value = "${data.terraform_remote_state.vpc.public_zone_id}"
}

output "common_name" {
  value = "${local.common_name}"
}

output "lb_account_id" {
  value = "${var.lb_account_id}"
}

output "role_arn" {
  value = "${var.role_arn}"
}

output "alfresco_app_name" {
  value = "${var.alfresco_app_name}"
}

output "environment_identifier" {
  value = "${var.environment_identifier}"
}

output "short_environment_identifier" {
  value = "${var.short_environment_identifier}"
}

output "remote_state_bucket_name" {
  value = "${var.remote_state_bucket_name}"
}

output "s3_lb_policy_file" {
  value = "policies/s3_alb_policy.json"
}

output "environment" {
  value = "${local.environment}"
}

output "remote_iam_role" {
  value = "${data.terraform_remote_state.remote_iam.alfresco_iam_arn}"
}

output "remote_config_bucket" {
  value = "${data.terraform_remote_state.remote_vpc.s3-config-bucket}"
}

output "monitoring_server_external_url" {
  value = "${data.terraform_remote_state.monitor.monitoring_server_external_url}"
}

output "monitoring_server_internal_url" {
  value = "${data.terraform_remote_state.monitor.monitoring_server_internal_url}"
}

output "monitoring_server_client_sg_id" {
  value = "${data.terraform_remote_state.monitor.monitoring_server_client_sg_id}"
}

output "private_subnet_map" {
  value = {
    az1 = "${data.terraform_remote_state.vpc.vpc_private-subnet-az1}"
    az2 = "${data.terraform_remote_state.vpc.vpc_private-subnet-az2}"
    az3 = "${data.terraform_remote_state.vpc.vpc_private-subnet-az3}"
  }
}

output "public_cidr_block" {
  value = [
    "${data.terraform_remote_state.vpc.vpc_public-subnet-az1-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_public-subnet-az2-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_public-subnet-az3-cidr_block}",
  ]
}

output "private_cidr_block" {
  value = [
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az1-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az2-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az3-cidr_block}",
  ]
}

output "db_cidr_block" {
  value = [
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az1-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az2-cidr_block}",
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az3-cidr_block}",
  ]
}

output "db_subnet_ids" {
  value = [
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az1}",
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az2}",
    "${data.terraform_remote_state.vpc.vpc_db-subnet-az3}",
  ]
}

output "public_subnet_ids" {
  value = [
    "${data.terraform_remote_state.vpc.vpc_public-subnet-az1}",
    "${data.terraform_remote_state.vpc.vpc_public-subnet-az2}",
    "${data.terraform_remote_state.vpc.vpc_public-subnet-az3}",
  ]
}

output "private_subnet_ids" {
  value = [
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az1}",
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az2}",
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az3}",
  ]
}

# Security groups
output "sg_map_ids" {
  value = "${local.sg_map_ids}"
}

# Alfresco hosts
output "app_hostnames" {
  value = "${local.app_hostnames}"
}

# nat gateways
output "nat_gateway_ips" {
  value = "${local.nat_gateways_ips}"
}
