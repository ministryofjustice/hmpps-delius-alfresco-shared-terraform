data "template_file" "asg_userdata" {
  template = "${file("../user_data/es_admin_non_ci.sh")}"

  vars {
    account_id           = "${local.account_id}"
    alf_backup_bucket    = "${local.backups_bucket}"
    alf_storage_bucket   = "${local.storage_s3bucket}"
    app_name             = "${local.application}"
    bastion_inventory    = "${local.bastion_inventory}"
    common_name          = "${local.common_name}"
    config-bucket        = "${local.config-bucket}"
    env_identifier       = "${local.environment_identifier}"
    environment          = "${local.environment}"
    environment_name     = "${var.environment_name}"
    internal_domain      = "${local.internal_domain}"
    private_domain       = "${local.internal_domain}"
    region               = "${var.region}"
    short_env_identifier = "${local.short_environment_identifier}"
    esadmin_version      = "${var.source_code_versions["esadmin"]}"
    redis_host           = "${aws_elasticache_cluster.redis.cache_nodes.0.address}"
    redis_port           = "${aws_elasticache_cluster.redis.cache_nodes.0.port}"
    log_group            = "${local.log_group}"
    worker_count         = 8
  }
}

resource "aws_launch_configuration" "esadmin" {
  name_prefix                 = "${local.common_name}-esadmin-"
  image_id                    = "${local.ami_id}"
  instance_type               = "c5.xlarge"
  iam_instance_profile        = "${local.instance_profile}"
  key_name                    = "${local.ssh_deployer_key}"
  security_groups             = ["${local.esadmin_sgs}", "${aws_security_group.redis.id}"]
  associate_public_ip_address = false
  user_data                   = "${data.template_file.asg_userdata.rendered}"
  enable_monitoring           = true
  ebs_optimized               = true

  root_block_device {
    volume_size = 60
  }

  lifecycle {
    create_before_destroy = true
  }
}
data "null_data_source" "tags" {
  count = "${length(keys(local.tags))}"

  inputs = {
    key                 = "${element(keys(local.tags), count.index)}"
    value               = "${element(values(local.tags), count.index)}"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "esadmin" {
  name                      = "${aws_launch_configuration.esadmin.name}"
  vpc_zone_identifier       = ["${local.private_subnet_ids}"]
  min_size                  = 5
  max_size                  = 5
  desired_capacity          = 5
  launch_configuration      = "${aws_launch_configuration.esadmin.name}"
  health_check_grace_period = 120
  termination_policies      = ["OldestInstance", "OldestLaunchTemplate", "OldestLaunchConfiguration"]
  health_check_type         = "EC2"
  metrics_granularity       = "${var.metrics_granularity}"
  enabled_metrics           = ["${var.enabled_metrics}"]

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    "${data.null_data_source.tags.*.outputs}",
    {
      key                 = "Name"
      value               = "${local.common_name}-esadmin"
      propagate_at_launch = true
    },
  ]
}
