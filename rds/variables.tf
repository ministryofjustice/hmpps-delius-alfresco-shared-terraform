# RDS
variable "region" {}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "rds_instance_class" {}

variable "rds_allocated_storage" {}

variable "db_parameters" {
    type = "list"
    default = [
        {
         name  = "max_connections"
         value = "800"
         apply_method = "pending-reboot"
        }
    ]
}
