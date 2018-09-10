variable "environment_identifier" {}

variable "environment" {}

variable "region" {}

variable "alfresco_app_name" {}

variable "private_subnet_ids" {
  type = "map"
}

variable depends_on {
  default = []
  type    = "list"
}

variable "tags" {
  type = "map"
}

variable "db_name" {}
variable "db_host" {}
variable "db_username" {}

variable "ami_id" {}

variable "account_id" {}

variable "access_logs_bucket" {}

variable "lb_security_groups" {
  type = "list"
}

variable "instance_security_groups" {
  type = "list"
}

variable "internal_domain" {}

variable "zone_id" {}

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

##################### ASG SECTION #####################
variable "service_desired_count" {}

variable "user_data" {}

variable "ebs_device_name" {}
variable "ebs_volume_type" {}
variable "ebs_volume_size" {}
variable "ebs_encrypted" {}

variable "instance_type" {}

variable "volume_size" {}

variable "az_asg_desired" {
  type = "map"
}

variable "az_asg_max" {
  type = "map"
}

variable "az_asg_min" {
  type = "map"
}

variable "associate_public_ip_address" {}

variable "cache_home" {}

variable "alfresco_instance_ami" {
  type    = "map"
  default = {}
}

variable "deploy_across_all_azs" {
  default = false
}

############### END OF ASG SECTION #####################

##################### CLOUDWATCH SECTION #####################
variable "cloudwatch_log_retention" {}

############### END OF CLOUDWATCH SECTION #####################

