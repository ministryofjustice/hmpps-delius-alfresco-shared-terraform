#-------------------------------------------------------------
### Getting the latest amazon ami
#-------------------------------------------------------------

data "aws_ami" "ecs_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["HMPPS ECS Centos master*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["${local.account_id}", "895523100917"] # MOJ
}

# ############################################
# # CREATE AUTO SCALING GROUP
# ############################################
data "template_file" "userdata_ecs" {
  template = "${file("../user_data/elasticsearch.sh")}"

  vars {
    app_name             = "${local.application}"
    bastion_inventory    = "${local.bastion_inventory}"
    env_identifier       = "${local.environment_identifier}"
    short_env_identifier = "${local.short_environment_identifier}"
    environment_name     = "${var.environment_name}"
    private_domain       = "${local.internal_domain}"
    account_id           = "${local.account_id}"
    internal_domain      = "${local.internal_domain}"
    environment          = "${local.environment}"
    common_name          = "${local.common_name}"
    es_cluster_name      = "${local.common_name}"
    ecs_cluster          = "${module.ecs_cluster.ecs_cluster_name}"
    efs_dns_name         = "${local.efs_dns_name}"
    alf_efs_dns_name     = "${local.alf_efs_dns_name}"
    efs_mount_path       = "${local.efs_mount_path}"
    migration_mount_path = "${local.migration_mount_path}"
    es_home_dir          = "${local.es_home_dir}"
    es_master_nodes      = "${var.elk_migration_props["es_master_nodes"]}"
    es_host_url          = "${aws_route53_record.internal_migration_dns.fqdn}:${local.port}"
    es_block_device      = "${var.elk_migration_props["block_device"]}"
  }
}

resource "aws_launch_configuration" "environment" {
  name_prefix                 = "${local.common_name}-"
  image_id                    = "${data.aws_ami.ecs_ami.id}"
  instance_type               = "${var.elk_migration_props["instance_type"]}"
  iam_instance_profile        = "${module.create-iam-instance-profile-es.iam_instance_name}"
  key_name                    = "${local.ssh_deployer_key}"
  security_groups             = ["${local.instance_security_groups}"]
  associate_public_ip_address = false
  user_data                   = "${data.template_file.userdata_ecs.rendered}"
  enable_monitoring           = true
  ebs_optimized               = "${var.ebs_optimized}"

  root_block_device {
    volume_type = "${var.volume_type}"
    volume_size = 60
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  ecs_tags = "${merge(local.tags, map("es_cluster_discovery", "${local.common_name}"))}"
}

data "null_data_source" "tags" {
  count = "${length(keys(local.ecs_tags))}"

  inputs = {
    key                 = "${element(keys(local.ecs_tags), count.index)}"
    value               = "${element(values(local.ecs_tags), count.index)}"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "environment" {
  name                      = "${local.common_name}"
  vpc_zone_identifier       = ["${local.private_subnet_ids}"]
  min_size                  = "${var.elk_migration_props["min_size"]}"
  max_size                  = "${var.elk_migration_props["max_size"]}"
  desired_capacity          = "${var.elk_migration_props["desired"]}"
  launch_configuration      = "${aws_launch_configuration.environment.name}"
  health_check_grace_period = 300
  termination_policies      = ["${var.termination_policies}"]
  health_check_type         = "${var.health_check_type}"
  metrics_granularity       = "${var.metrics_granularity}"
  enabled_metrics           = ["${var.enabled_metrics}"]

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    "${data.null_data_source.tags.*.outputs}",
    {
      key                 = "Name"
      value               = "${local.common_name}"
      propagate_at_launch = true
    },
  ]
}
