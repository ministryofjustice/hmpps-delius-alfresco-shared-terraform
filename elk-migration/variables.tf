variable "region" {}

variable "role_arn" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "cloudwatch_log_retention" {}

variable "bastion_inventory" {
  default = "dev"
}

variable "environment_name" {}

variable "availability_zone" {
  description = "List of the three AZs we want to use"
  type        = "map"
}

# Elasticsearch

variable "ebs_optimized" {
  default = "false"
}

variable "volume_type" {
  default = "standard"
}

variable "elk_migration_props" {
  type = "map"
  default = {
    min_size                        = 2
    max_size                        = 2
    desired                         = 2
    ecs_cpu_units                   = 500
    ecs_memory                      = 6000
    jvm_heap_size                   = "5g"
    image_url                       = "mojdigitalstudio/hmpps-elasticsearch-5:latest"
    kibana_image_url                = "mojdigitalstudio/hmpps-kibana-5:0.0.349-alpha"
    logstash_image_url              = "mojdigitalstudio/hmpps-logstash:latest"
    block_device                    = "/dev/nvme1n1"
    es_master_nodes                 = 1
    ecs_service_desired_count       = 2
    instance_type                   = "m5d.xlarge"
    kibana_instance_type            = "m4.large"
    kibana_desired_count            = 1
    kibana_asg_size                 = 1
    logstash_desired_count          = 1
    provisioned_throughput_in_mibps = 10
    throughput_mode                 = "provisioned"
    ssl_policy                      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  }
}

# kibana
variable "kibana_short_name" {
  default = ""
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

variable "alf_cognito_map" {
  type = "map"
  default = {
    minimum_length               = 12
    require_symbols              = false
    unused_account_validity_days = 2
  }
}
