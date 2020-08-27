variable "cluster_id" {
}

variable "domain" {
}

variable "zone_id" {
}

variable "parameter_group_name" {
}

variable "subnet_group_name" {
}

variable "security_group_ids" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

variable "maintenance_window" {
  default     = "wed:03:00-wed:04:00"
  description = "Maintenance window"
}

variable "cluster_size" {
  default     = "1"
  description = "Cluster size"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "Elastic cache instance type"
}

variable "engine_version" {
  default     = "1.4.33"
  description = "Engine version"
}

variable "notification_topic_arn" {
  default     = ""
  description = "Notification topic arn"
}

variable "alarm_cpu_threshold_percent" {
  default     = "75"
  description = "CPU threshold alarm level"
}

variable "alarm_memory_threshold_bytes" {
  # 10MB
  default     = "10000000"
  description = "Alarm memory threshold bytes"
}

variable "alarm_actions" {
  type        = list(string)
  default     = []
  description = "Alarm actions"
}

variable "apply_immediately" {
  default     = "true"
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
}

