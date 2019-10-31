####################################################
# IAM - Application specific
####################################################
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

#ES-Admin
output "iam_instance_es_admin_role_name" {
  value = "${module.create-iam-app-role-es.iamrole_name}"
}

output "iam_instance_es_admin_role_arn" {
  value = "${module.create-iam-app-role-es.iamrole_arn}"
}

output "iam_instance_es_admin_profile_name" {
  value = "${module.create-iam-instance-profile-es.iam_instance_name}"
}

output "es_admin_policy_name" {
  value = "${module.create-iam-app-policy-es.iampolicy_name}"
}
