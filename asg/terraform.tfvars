terragrunt = {
  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = ["../common",
      "../securty-groups",
      "../rds",
      "../iam",
      "../s3buckets",
    ]
  }
}
