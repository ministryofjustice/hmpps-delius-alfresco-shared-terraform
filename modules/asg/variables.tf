variable "environment_identifier" {}

variable "environment" {}

variable "region" {}

variable "vpc_id" {}


variable "alfresco_app_name" {}

variable "private_subnet_ids" {
  type = "map"
}

variable "public_subnet_ids" {
  type = "list"
}

variable "app_hostnames" {
  type = "map"
}

variable depends_on {
  default = []
  type    = "list"
}

variable "tags" {
  type = "map"
}

variable "monitoring_server_url" {}

variable "db_name" {}
variable "db_host" {}
variable "db_username" {}
variable "db_password" {}

variable "ami_id" {}

variable "common_name" {}

variable "account_id" {}

variable "access_logs_bucket" {}

variable "lb_security_groups" {
  type = "list"
}

variable "instance_security_groups" {
  type = "list"
}

variable "internal_domain" {}

variable "external_domain" {}

variable "zone_id" {}

variable "public_zone_id" {}

variable "alfresco_s3bucket" {}

variable "bucket_kms_key_id" {}

variable "ssh_deployer_key" {}

variable "short_environment_identifier" {}

variable "instance_profile" {}

variable "internal" {
  description = "If true, ELB will be an internal ELB"
}

variable "cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  default     = true
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  default     = 60
}

variable "connection_draining" {
  description = "Boolean to enable connection draining"
  default     = false
}

variable "connection_draining_timeout" {
  description = "The time in seconds to allow for connections to drain"
  default     = 300
}

variable "listener" {
  description = "A list of listener blocks"
  type        = "list"
}

variable "access_logs" {
  description = "An access logs block"
  type        = "list"
  default     = []
}

variable "health_check" {
  description = "A health check block"
  type        = "list"
}

variable "certificate_arn" {}

variable "enable_deletion_protection" {
  default = "false"
}

##################### ASG SECTION #####################
variable "service_desired_count" {}

variable "user_data" {}

variable "ebs_device_name" {}
variable "ebs_volume_type" {}
variable "ebs_volume_size" {}
variable "ebs_encrypted" {}

variable "instance_type" {}

variable "volume_size" {}

variable "az_asg_desired" {}

variable "az_asg_max" {}

variable "az_asg_min" {}

variable "associate_public_ip_address" {}

variable "cache_home" {}

variable "deploy_across_all_azs" {
  default = false
}

variable "bastion_inventory" {
  default = "dev"
}

variable "jvm_memory" {}

############### END OF ASG SECTION #####################

##################### CLOUDWATCH SECTION #####################
variable "cloudwatch_log_retention" {}

############### END OF CLOUDWATCH SECTION #####################

## NGINX
variable "keys_dir" {}

variable "self_signed_ssm" {
  type = "map"
}

variable "config_bucket" {}

variable "tomcat_host" {
  description = "Alfresco host"
  default     = "localhost"
}

variable "tomcat_port" {
  description = "Alfresco port"
  default     = "8080"
}

variable "messaging_broker_url" {
  default = "localhost:61616"
}

variable "messaging_broker_password" {}

variable "logstash_host_fqdn" {
  default = "logstash"
}

variable "kibana_host" {
  default = "http://kibana:5601"
}

variable "elasitcsearch_host" {
  default = "http://elasitcsearch"
}


variable "enable_monitoring" {
  default = "true"
}

variable "ebs_optimized" {
  default = "false"
}

variable "ebs_delete_on_termination" {
  default = true
}

variable "volume_type" {
  default = "standard"
}

variable "health_check_grace_period" {
  default = 300
}

variable "metrics_granularity" {
  default = "1Minute"
}

variable "health_check_type" {
  default = "ELB"
}

variable "enabled_metrics" {
  type = "list"
  default = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]
}

variable "termination_policies" {
  type    = "list"
  default = ["OldestInstance", "OldestLaunchTemplate", "OldestLaunchConfiguration"]
}

variable "logs_kms_arn" {}

variable "cookie_duration" {
  default = "3600"
}

variable "min_elb_capacity" {
  default = 1
}
