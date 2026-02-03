include {
  path = "${find_in_parent_folders()}"
}

dependencies {
  paths = [
    "../common",
    "../iam",
    "../security-groups"
  ]
}

dependency "common" {
  config_path = "../common"
}

inputs = {
  environment = dependency.common.outputs.environment
}
