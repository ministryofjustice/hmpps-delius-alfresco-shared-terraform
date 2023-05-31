# Common variables
variable "environment_identifier" {
  description = "resource label or name"
}

variable "region" {
  description = "The AWS region."
}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "alf_cloudwatch_log_retention" {
}

variable "alfresco_search_solr_props" {
  type = map(string)
  default = {
    cpu                       = "1024"
    memory                    = "4096"
    app_port                  = "8983"
    heap_size                 = "1500"
    image_url                 = "alfresco/alfresco-search-services"
    version                   = "2.0.2"
    ebs_size                  = "100"
    ebs_iops                  = "100"
    ebs_type                  = "gp2"
    ssm_prefix                = "/alfresco/ecs"
    desired_count             = "3"
    cookie_duration           = "3600"
    backup_schedule           = "cron(0 01 * * ? *)"
    backup_cold_storage_after = 0
    backup_delete_after       = 7
    snap_tag                  = "CreateSnapshotSolr"
  }
}

variable "alfresco_search_solr_configs" {
  type    = map(string)
  default = {}
}

variable "alfresco_search_solr_configs_overrides" {
  type    = map(string)
  default = {}
}

variable "alf_stop_services" {
  type    = string
  default = "no"
}

variable "alf_push_to_cloudwatch" {
  default = "no"
}

variable "cleanup_scheduler_expression" {
  description = "Schedule to run solr EBS vols cleanup scheduler on a daily basis"
  default = "cron(00 08 * * ? *)"
}

variable "solr_cache_vols_days_limit" {
  description = "Set days limit of how old a solr cache EBS volume should be. If unattached solr cache volumes are older than  this days limit number, the volume will be removed using the cleanup scheduler"
  default = 5
}

variable "enable_cleanup_scheduler" {
  default = true
}
