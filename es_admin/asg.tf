resource "aws_launch_configuration" "esadmin" {
  name_prefix                 = "${local.common_name}-esadmin-"
  image_id                    = "${local.ami_id}"
  instance_type               = "${var.es_admin_instance_type}"
  iam_instance_profile        = "${local.instance_profile}"
  key_name                    = "${local.ssh_deployer_key}"
  security_groups             = ["${local.instance_security_groups}"]
  associate_public_ip_address = false
  user_data                   = "${data.template_file.instance_userdata.rendered}"
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
  min_size                  = 0
  max_size                  = 0
  desired_capacity          = 0
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
