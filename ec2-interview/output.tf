output "ssh_deployer_key_private" {
  value     = module.ssh_key.private_key_pem
  sensitive = true
}

output "public_ip" {
  value = aws_instance.instance.public_ip
}

output "role_name" {
  value = module.iam_role.iamrole_name
}

output "role_arn" {
  value = module.iam_role.iamrole_name
}

# PROFILE
output "instance_profile_name" {
  value = module.iam_profile.iam_instance_name
}

output "bucket_name" {
  value = aws_s3_bucket.bucket.id
}
