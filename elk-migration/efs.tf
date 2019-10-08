####################################################
# EFS content
####################################################
# module "efs" {
#   source                          = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//efs"
#   environment_identifier          = "${local.application}-efs"
#   tags                            = "${local.tags}"
#   encrypted                       = true
#   kms_key_id                      = "${local.storage_kms_arn}"
#   performance_mode                = "generalPurpose"
#   provisioned_throughput_in_mibps = "${var.elk_migration_props["provisioned_throughput_in_mibps"]}"
#   throughput_mode                 = "${var.elk_migration_props["throughput_mode"]}"
#   share_name                      = "${local.application}-efs"
#   zone_id                         = "${local.private_zone_id}"
#   domain                          = "${local.internal_domain}"
#   subnets                         = "${local.private_subnet_ids}"
#   security_groups                 = ["${local.efs_security_groups}"]
# }

resource "aws_efs_file_system" "efs" {
  creation_token                  = "${local.common_name}-efs"
  kms_key_id                      = "${local.storage_kms_arn}"
  encrypted                       = true
  performance_mode                = "generalPurpose"
  provisioned_throughput_in_mibps = "${var.elk_migration_props["provisioned_throughput_in_mibps"]}"
  throughput_mode                 = "${var.elk_migration_props["throughput_mode"]}"

  tags = "${merge(
    local.tags,
    map("Name", "${local.common_name}-efs")
  )}"
}


###############################################
# Create efs mount target
###############################################
resource "aws_efs_mount_target" "efs" {
  count           = "${length(local.private_subnet_ids)}"
  file_system_id  = "${aws_efs_file_system.efs.id}"
  subnet_id       = "${element(compact(local.private_subnet_ids), count.index)}"
  security_groups = ["${local.efs_security_groups}"]
}
