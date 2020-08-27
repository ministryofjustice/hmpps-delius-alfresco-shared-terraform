####################################################
# EFS content
####################################################

resource "aws_efs_file_system" "efs" {
  creation_token                  = "${local.common_name}-efs"
  kms_key_id                      = local.storage_kms_arn
  encrypted                       = true
  performance_mode                = "generalPurpose"
  provisioned_throughput_in_mibps = var.elk_migration_props["provisioned_throughput_in_mibps"]
  throughput_mode                 = var.elk_migration_props["throughput_mode"]

  tags = merge(
    local.tags,
    {
      "Name" = "${local.common_name}-efs"
    },
  )
}

###############################################
# Create efs mount target
###############################################
resource "aws_efs_mount_target" "efs" {
  count          = length(local.private_subnet_ids)
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = element(compact(flatten(local.private_subnet_ids)), count.index)
  security_groups = flatten(local.efs_security_groups)
}

