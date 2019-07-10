# EXTERNAL

# IAM
output "iam_role_ext_ecs_role_arn" {
  value = "${module.create-iam-ecs-role-ext.iamrole_arn}"
}

output "iam_role_ext_ecs_role_name" {
  value = "${module.create-iam-ecs-role-ext.iamrole_name}"
}

# APP ROLE
output "iam_policy_ext_app_role_name" {
  value = "${module.create-iam-app-role-ext.iamrole_name}"
}

output "iam_policy_ext_app_role_arn" {
  value = "${module.create-iam-app-role-ext.iamrole_arn}"
}

# PROFILE
output "iam_policy_ext_app_instance_profile_name" {
  value = "${module.create-iam-instance-profile-ext.iam_instance_name}"
}

# INTERNAL

# APP ROLE
output "iam_policy_int_app_role_name" {
  value = "${module.create-iam-app-role-int.iamrole_name}"
}

output "iam_policy_int_app_role_arn" {
  value = "${module.create-iam-app-role-int.iamrole_arn}"
}

# PROFILE
output "iam_policy_int_app_instance_profile_name" {
  value = "${module.create-iam-instance-profile-int.iam_instance_name}"
}
