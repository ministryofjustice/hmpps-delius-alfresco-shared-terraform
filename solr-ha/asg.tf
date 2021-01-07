# ############################################
# # CREATE USER DATA FOR EC2 RUNNING SERVICES
# ############################################

data "template_file" "user_data" {
  template = file("./templates/solr_user_data.sh")

  vars = {
    env_identifier             = local.environment_identifier
    short_env_identifier       = local.short_environment_identifier
    app_name                   = local.alfresco_app_name
    cldwatch_log_group         = module.create_loggroup.loggroup_name
    region                     = var.region
    app_name                   = local.alfresco_app_name
    route53_sub_domain         = "${local.alfresco_app_name}.${local.environment}"
    private_domain             = local.internal_domain
    private_zone_id            = local.private_zone_id
    account_id                 = local.account_id
    internal_domain            = local.internal_domain
    elasticsearch_url          = local.elasticsearch_props["url"]
    elasticsearch_cluster_name = local.elasticsearch_props["cluster_name"]
    s3_bucket_config           = local.config-bucket
    ssm_get_command            = "aws --region ${var.region} ssm get-parameters --names"
    #s3 config data
    bucket_name         = local.s3bucket
    bucket_encrypt_type = "kms"
    bucket_key_id       = local.s3bucket_kms_id
    external_fqdn       = "localhost"
    # For bootstrapping
    bastion_inventory    = var.bastion_inventory
    bootstrap_version    = var.source_code_versions["boostrap"]
    alfresco_version     = var.source_code_versions["alfresco"]
    logstash_version     = var.source_code_versions["logstash"]
    elasticbeats_version = var.source_code_versions["elasticbeats"]
    solr_version         = var.source_code_versions["solr_ha"]
    # SOLR
    solr_host             = local.solr_host
    solr_port             = local.solr_port
    solr_data_device_name = local.solr_asg_props["ebs_device_name"]
    solr_java_xms         = local.solr_asg_props["java_xms"]
    solr_java_xmx         = local.solr_asg_props["java_xmx"]
    jvm_memory            = local.solr_asg_props["alf_jvm_memory"]
    backups_bucket        = local.backups_bucket
    solr_temp_device_name = local.solr_asg_props["ebs_temp_device_name"]
    solr_temp_dir         = "/opt/solr/tmp"
    alfresco_host         = local.tracker_host
    alfresco_port         = 80
    alfresco_ssl_port     = 443
    prefix                = local.common_name
  }
}

# ############################################
# # CREATE LAUNCH CONFIG FOR EC2 RUNNING SERVICES
# ############################################

resource "aws_launch_configuration" "environment" {
  name_prefix                 = "${local.common_name}-"
  image_id                    = local.solr_asg_props["ami_id"]
  instance_type               = local.solr_asg_props["ha_instance_type"]
  iam_instance_profile        = data.terraform_remote_state.iam.outputs.solr_profile_name
  key_name                    = data.terraform_remote_state.common.outputs.common_ssh_deployer_key
  security_groups             = flatten(local.instance_security_groups)
  associate_public_ip_address = false
  user_data                   = data.template_file.user_data.rendered
  enable_monitoring           = true
  ebs_optimized               = false

  root_block_device {
    volume_type = "gp2"
    volume_size = 50
    encrypted   = true
  }

  lifecycle {
    create_before_destroy = true
  }

  ebs_block_device {
    device_name           = "/dev/xvdb"
    volume_type           = "gp2"
    volume_size           = 50
    encrypted             = true
    delete_on_termination = true
  }
}

# ############################################
# # CREATE AUTO SCALING GROUP
# ############################################
resource "aws_placement_group" "environment" {
  name     = "${local.common_name}-pg"
  strategy = "spread"
}

data "null_data_source" "tags" {
  count = length(keys(local.tags))

  inputs = {
    key                 = element(keys(local.tags), count.index)
    value               = element(values(local.tags), count.index)
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "asg_az1" {
  name                      = "${aws_launch_configuration.environment.name}-az1"
  vpc_zone_identifier       = [element(flatten(local.private_subnet_ids), 0)]
  min_size                  = var.restoring == "enabled" ? 0 : 1
  max_size                  = var.restoring == "enabled" ? 0 : 1
  desired_capacity          = var.restoring == "enabled" ? 0 : 1
  launch_configuration      = aws_launch_configuration.environment.name
  health_check_grace_period = 600
  placement_group           = aws_placement_group.environment.id
  target_group_arns         = [aws_lb_target_group.environment.arn]
  health_check_type         = "ELB"
  metrics_granularity       = "1Minute"
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
  default_cooldown = "60"

  lifecycle {
    create_before_destroy = true
  }
  tags = concat(
    [
      {
        key                 = "Name"
        value               = "${aws_launch_configuration.environment.name}-az1"
        propagate_at_launch = true
      }
    ],
    data.null_data_source.tags.*.outputs
  )
}

resource "aws_autoscaling_group" "asg_az2" {
  name                      = "${aws_launch_configuration.environment.name}-az2"
  vpc_zone_identifier       = [element(flatten(local.private_subnet_ids), 1)]
  min_size                  = var.restoring == "enabled" ? 0 : 1
  max_size                  = var.restoring == "enabled" ? 0 : 1
  desired_capacity          = var.restoring == "enabled" ? 0 : 1
  launch_configuration      = aws_launch_configuration.environment.name
  health_check_grace_period = 600
  placement_group           = aws_placement_group.environment.id
  target_group_arns         = [aws_lb_target_group.environment.arn]
  health_check_type         = "ELB"
  metrics_granularity       = "1Minute"
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
  default_cooldown = "60"

  lifecycle {
    create_before_destroy = true
  }
  tags = concat(
    [
      {
        key                 = "Name"
        value               = "${aws_launch_configuration.environment.name}-az2"
        propagate_at_launch = true
      }
    ],
    data.null_data_source.tags.*.outputs
  )
}

resource "aws_autoscaling_group" "asg_az3" {
  name                      = "${aws_launch_configuration.environment.name}-az3"
  vpc_zone_identifier       = [element(flatten(local.private_subnet_ids), 2)]
  min_size                  = var.restoring == "enabled" ? 0 : 1
  max_size                  = var.restoring == "enabled" ? 0 : 1
  desired_capacity          = var.restoring == "enabled" ? 0 : 1
  launch_configuration      = aws_launch_configuration.environment.name
  health_check_grace_period = 600
  placement_group           = aws_placement_group.environment.id
  target_group_arns         = [aws_lb_target_group.environment.arn]
  health_check_type         = "ELB"
  metrics_granularity       = "1Minute"
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
  default_cooldown = "60"

  lifecycle {
    create_before_destroy = true
  }
  tags = concat(
    [
      {
        key                 = "Name"
        value               = "${aws_launch_configuration.environment.name}-az3"
        propagate_at_launch = true
      }
    ],
    data.null_data_source.tags.*.outputs
  )
}
