# RDS
variable "region" {
}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "environment_name" {
}

#ASG
variable "alfresco_asg_props" {
  type = map(string)
  default = {
    asg_desired               = 1
    asg_min                   = 1
    asg_max                   = 2
    asg_instance_type         = "m4.xlarge"
    ebs_volume_size           = 512
    health_check_grace_period = 600
    min_elb_capacity          = 1
    wait_for_capacity_timeout = "30m"
    default_cooldown          = 120
  }
}

variable "alf_config_map" {
  type    = map(string)
  default = {}
}

variable "source_code_versions" {
  type = map(string)
  default = {
    boostrap     = "centos"
    alfresco     = "master"
    logstash     = "master"
    elasticbeats = "master"
    solr         = "master"
  }
}

variable "alf_cloudwatch_log_retention" {
}

variable "bastion_inventory" {
  default = "dev"
}

variable "alfresco_jvm_memory" {
  description = "jvm memmory"
}

variable "spg_messaging_broker_url" {
  default     = "localhost:61616"
  description = "SPG messaging broker url"
}

# Introduce a switch variable to allow the messaging broker url to be specified from the spg_messaging_broker_url
# variable (var) or from the remote state file which is generated by the AmazonMQ broker (data).
# Add spg_messaging_broker_url_src = "var" to the alfresco env-configs for an environment where there is no AmazonMQ
variable "spg_messaging_broker_url_src" {
  default     = "data"
  description = "var -> variable.spg_messaging_broker_url | data -> data.terraform.remote_state.amazonmq.amazon_mq_broker_connect_url"
}

variable "alf_ebs_volume_size" {
  default = "512"
}

variable "alfresco_volume_size" {
  default = 20
}

variable "cookie_duration" {
  default = "3600"
}

variable "user_access_cidr_blocks" {
  type = list(string)
}

variable "restoring" {
  default = "disabled"
}

variable "min_elb_capacity" {
  default = 1
}

variable "wait_for_capacity_timeout" {
  default = "15m"
}

variable "alf_solr_config" {
  type = map(string)
  default = {
    solr_host = "alf-solr"
    solr_port = 443
  }
}