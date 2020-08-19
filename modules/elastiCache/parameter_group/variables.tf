variable "family" {
  default     = "memcached1.5"
  description = "AWS memcached family"
}

variable "max_item_size" {
  default     = "10485760"
  description = "Max item size"
}

variable "name" {
  description = "The Name of the application or solution  (e.g. `bastion` or `portal`)"
}

