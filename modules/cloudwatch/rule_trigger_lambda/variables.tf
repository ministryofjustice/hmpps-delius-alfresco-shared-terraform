variable "target_function" {
  type = map(string)
  default = {
    name     = ""
    id       = ""
    arn      = ""
    input    = ""
    schedule = ""
  }
}
