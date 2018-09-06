terragrunt = {
  include {
    path = "${find_in_parent_folders()}"
  }
}

s3_lb_policy_file = "s3_alb_policy.json"
