variable "https_listener_rules" {
  description = "A list of maps describing the Listener Rules for this ALB. Required key/values: actions, conditions. Optional key/values: priority, https_listener_index (default to https_listeners[count.index])"
  type        = any
  default     = []
}

variable "create_rules" {
  description = "Controls if the rules should be created"
  type        = bool
  default     = true
}

variable "listener_arn_list" {
  type = list
}

variable "target_group_list" {
  type = list
}
