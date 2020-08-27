include {
  path = "${find_in_parent_folders()}"
}

dependencies {
  paths = [
    "../common",
    "../s3buckets",
    "../iam",
    "../security-groups",
    "../rds",
    "../efs"
  ]
}
