resource "aws_placement_group" "ecs" {
  name     = local.common_name
  strategy = "spread"
  tags     = local.tags
}

# Host Launch Configuration
resource "aws_launch_configuration" "ecs_host_lc" {
  name_prefix                 = "${local.common_name}-asg"
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ecs_host_profile.name
  image_id                    = data.aws_ami.ecs_ami.id
  instance_type               = local.alf_ecs_config["ecs_instance_type"]

  security_groups = [
    local.ecs_security_groups["host"],
    local.ecs_security_groups["efs"]
  ]

  user_data_base64 = base64encode(data.template_file.ecs_host_userdata_template.rendered)
  key_name         = local.ssh_deployer_key

  lifecycle {
    create_before_destroy = true
  }
}

# Host ASG
resource "aws_autoscaling_group" "ecs_asg" {
  name                 = "${local.common_name}-host-asg"
  launch_configuration = aws_launch_configuration.ecs_host_lc.id

  # Not setting desired count as that could cause scale in when deployment runs and lead to resource exhaustion
  max_size              = tonumber(local.alf_ecs_config["node_max_count"])
  min_size              = tonumber(local.alf_ecs_config["node_min_count"])
  protect_from_scale_in = true # scale-in is managed by ECS
  vpc_zone_identifier   = flatten(local.private_subnet_ids)

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }

  dynamic "tag" {
    for_each = merge(local.tags, {
      Name             = "${local.common_name}-host-asg"
      AmazonECSManaged = "" # Required when using ecs_capacity_provider for scaling
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Additional capacity provider added in AZ1 as a workaround to a tech debt item
# The implementation of solr's storage setup ties ECS tasks to AZs.
# So, without a storage backend re-work, we need to ensure there is capacity in selected AZ for a solr task
resource "aws_autoscaling_group" "ecs_az1_asg" {
  name                 = "${local.common_name}-host-az1-asg"
  launch_configuration = aws_launch_configuration.ecs_host_lc.id

  # Not setting desired count as that could cause scale in when deployment runs and lead to resource exhaustion
  max_size              = 1
  min_size              = 1
  protect_from_scale_in = true # scale-in is managed by ECS
  vpc_zone_identifier   = [data.terraform_remote_state.common.outputs.private_subnet_map["az1"]]

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }

  dynamic "tag" {
    for_each = merge(local.tags, {
      Name             = "${local.common_name}-host-az1-asg"
      AmazonECSManaged = "" # Required when using ecs_capacity_provider for scaling
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
