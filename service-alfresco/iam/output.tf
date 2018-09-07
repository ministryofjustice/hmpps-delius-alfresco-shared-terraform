# INTERNAL

# APP ROLE
output "service_alfresco_iam_policy_int_app_role_name" {
  value = "${module.create-iam-app-role-int.iamrole_name}"
}

output "service_alfresco_iam_policy_int_app_role_arn" {
  value = "${module.create-iam-app-role-int.iamrole_arn}"
}

# PROFILE
output "service_alfresco_iam_policy_int_app_instance_profile_name" {
  value = "${module.create-iam-instance-profile-int.iam_instance_name}"
}
