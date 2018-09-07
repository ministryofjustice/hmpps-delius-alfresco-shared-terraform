terragrunt = {
  include {
    path = "${find_in_parent_folders()}"
  }

  dependencies {
    paths = ["../../common", "../s3bucket"]
  }
}

ec2_policy_file = "ec2_policy.json"

ec2_role_policy_file = "policies/ec2_role_policy.json"
