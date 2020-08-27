variable "s3_bucket_name" {
}

variable "acl" {
  default = "private"
}

variable "tags" {
  type = map(string)
}

variable "versioning" {
  default = true
}

