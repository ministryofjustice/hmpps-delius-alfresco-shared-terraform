####################################################
# IAM - Application specific
####################################################
# EXTERNAL

# IAM
output "iam_role_ext_ecs_role_arn" {
  value = "${module.iam.iam_role_ext_ecs_role_arn}"
}

output "iam_role_ext_ecs_role_name" {
  value = "${module.iam.iam_role_ext_ecs_role_name}"
}

# APP ROLE
output "iam_policy_ext_app_role_name" {
  value = "${module.iam.iam_policy_ext_app_role_name}"
}

output "iam_policy_ext_app_role_arn" {
  value = "${module.iam.iam_policy_ext_app_role_arn}"
}

# PROFILE
output "iam_policy_ext_app_instance_profile_name" {
  value = "${module.iam.iam_policy_ext_app_instance_profile_name}"
}

# INTERNAL

# APP ROLE
output "iam_policy_int_app_role_name" {
  value = "${module.iam.iam_policy_int_app_role_name}"
}

output "iam_policy_int_app_role_arn" {
  value = "${module.iam.iam_policy_int_app_role_arn}"
}

# PROFILE
output "iam_policy_int_app_instance_profile_name" {
  value = "${module.iam.iam_policy_int_app_instance_profile_name}"
}
