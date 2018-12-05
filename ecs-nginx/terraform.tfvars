terragrunt = {
  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = [
      "../common",
      "../certs",
      "../s3buckets"
      "../iam",
      "../security-groups",
      "../rds",
      "../asg",
    ]
  }
}
