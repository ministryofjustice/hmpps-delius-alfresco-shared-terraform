# RDS
variable "region" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

#ASG
variable "alfresco_asg_props" {
  type = "map"
  default = {
    asg_desired       = 1
    asg_min           = 1
    asg_max           = 2
    asg_instance_type = "m4.xlarge"
    # asg_ami                   = "ami-0daf390b7cd42be97"
    ebs_volume_size           = 512
    health_check_grace_period = 600
    min_elb_capacity          = 1
    wait_for_capacity_timeout = "30m"
    default_cooldown          = 120
    ami_name                  = "HMPPS Alfresco master*"
  }
}

variable "alf_metrics_props" {
  type = "map"
  default = {
    metrics_granularity = "1Minute"
    enabled_metrics = [
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
}


variable "alf_cloudwatch_log_retention" {}

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
variable spg_messaging_broker_url_src {
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

variable "alf_solr_config" {
  type = "map"
  default = {
    solr_host          = "alf-solr"
    solr_port          = 443
    ebs_size           = 20
    ebs_iops           = 100
    ebs_type           = "gp2"
    ebs_device_name    = "/dev/xvdc"
    java_xms           = "4000m"
    java_xmx           = "4000m"
    alf_jvm_memory     = "4000m"
    schedule           = "cron(0 01 * * ? *)"
    cold_storage_after = 14
    delete_after       = 120
    snap_tag           = "CreateSnapshotSolr"
  }
}

variable "user_access_cidr_blocks" {
  type = "list"
}
