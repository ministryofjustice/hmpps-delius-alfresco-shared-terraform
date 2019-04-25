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

# ECS
output "iam_service_ecs_es_role_arn" {
  value = "${module.create-iam-ecs-role-int.iamrole_arn}"
}

output "iam_service_ecs_es_role_name" {
  value = "${module.create-iam-ecs-role-int.iamrole_name}"
}

#ES
output "iam_instance_ecs_es_role_name" {
  value = "${module.create-iam-app-role-es.iamrole_name}"
}

output "iam_instance_ecs_es_role_arn" {
  value = "${module.create-iam-app-role-es.iamrole_arn}"
}

output "iam_instance_ecs_es_profile_name" {
  value = "${module.create-iam-instance-profile-es.iam_instance_name}"
}
