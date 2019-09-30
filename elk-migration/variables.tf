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
variable "es_instance_type" {
  default = "m5d.xlarge"
}

variable "ebs_optimized" {
  default = "false"
}

variable "volume_type" {
  default = "standard"
}

variable "elk_migration_props" {
  type = "map"
  default = {
    min_size                  = 3
    max_size                  = 3
    desired                   = 3
    ecs_mem_limit             = 12300
    ecs_cpu_units             = 500
    ecs_memory                = 12500
    jvm_heap_size             = "12g"
    image_url                 = "mojdigitalstudio/hmpps-elasticsearch-5:latest"
    kibana_image_url          = "mojdigitalstudio/hmpps-kibana:latest"
    logstash_image_url        = "mojdigitalstudio/hmpps-logstash:latest"
    block_device              = "/dev/nvme1n1"
    es_master_nodes           = 2
    ecs_service_desired_count = 3
    instance_type             = "m5d.xlarge"
  }
}

# kibana
variable "kibana_short_name" {
  default = ""
}
