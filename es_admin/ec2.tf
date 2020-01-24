locals {
  efs_mount_path = "/opt/es_backup"
  efs_dns_name   = "${data.terraform_remote_state.monitoring.monitoring_server_efs_share_dns}"
  es_home_dir    = "/usr/share/elasticsearch"
}

####################################################
# instance 1
####################################################

data "template_file" "instance_userdata" {
  template = "${file("../user_data/es_admin_userdata.sh")}"

  vars {
    account_id           = "${local.account_id}"
    alf_backup_bucket    = "${local.backups_bucket}"
    alf_efs_dns_name     = "${local.alf_efs_dns_name}"
    alf_storage_bucket   = "${local.storage_s3bucket}"
    app_name             = "${local.application}"
    bastion_inventory    = "${local.bastion_inventory}"
    common_name          = "${local.common_name}"
    config-bucket        = "${local.config-bucket}"
    efs_dns_name         = "${local.efs_dns_name}"
    efs_mount_path       = "${local.efs_mount_path}"
    env_identifier       = "${local.environment_identifier}"
    environment          = "${local.environment}"
    environment_name     = "${var.environment_name}"
    es_block_device      = "${var.es_admin_volume_props["device_name"]}"
    es_home_dir          = "${local.es_home_dir}"
    internal_domain      = "${local.internal_domain}"
    private_domain       = "${local.internal_domain}"
    region               = "${var.region}"
    short_env_identifier = "${local.short_environment_identifier}"
    ssm_tls_ca_cert      = "${local.ssm_tls_ca_cert}"
    ssm_tls_cert         = "${local.ssm_tls_cert}"
    ssm_tls_private_key  = "${local.ssm_tls_private_key}"
  }
}

#-------------------------------------------------------------
### Create instance 
#-------------------------------------------------------------

resource "aws_instance" "instance" {
  ami                         = "${local.ami_id}"
  instance_type               = "${var.es_admin_instance_type}"
  subnet_id                   = "${local.private_subnet_ids[0]}"
  iam_instance_profile        = "${local.instance_profile}"
  associate_public_ip_address = false
  vpc_security_group_ids      = ["${local.instance_security_groups}"]
  key_name                    = "${local.ssh_deployer_key}"
  monitoring                  = true
  user_data                   = "${data.template_file.instance_userdata.rendered}"

  tags = "${merge(
    local.tags,
    map("Name", "${local.common_name}-${local.application}"),
    map("CreateSnapshot", "${var.es_admin_volume_props["create_snapshot"]}")
  )}"

  root_block_device {
    volume_size = "60"
  }
  ebs_block_device {
    delete_on_termination = true
    iops                  = "${var.es_admin_volume_props["iops"]}"
    volume_type           = "${var.es_admin_volume_props["type"]}"
    device_name           = "${var.es_admin_volume_props["device_name"]}"
    volume_size           = "${var.es_admin_volume_props["size"]}"
    encrypted             = "${var.es_admin_volume_props["encrypted"]}"
  }
  # lifecycle {
  #   ignore_changes = [
  #     "ami"
  #   ]
  # }
}

#-------------------------------------------------------------
# Create route53 entry for instance 1
#-------------------------------------------------------------

resource "aws_route53_record" "instance" {
  zone_id = "${local.public_zone_id}"
  name    = "${local.application}.${local.external_domain}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.instance.private_ip}"]
}
