variable "cluster_name" {
}

variable "tags" {
  type = map(string)

  default = {
    name = "ecs-cluster"
  }
}

