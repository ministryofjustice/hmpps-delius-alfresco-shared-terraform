locals {
  ebs_iops = local.solr_asg_props["ebs_iops"]
  ebs_type = local.solr_asg_props["ebs_type"]
}

# EBS
data "aws_subnet" "selected" {
  id = element(flatten(local.private_subnet_ids), 0)
}

data "aws_ssm_parameter" "snapshot" {
  name = "/alfresco/solr/ebs/snapshot_id"
}

resource "aws_ebs_volume" "solr" {
  availability_zone = data.aws_subnet.selected.availability_zone
  encrypted         = true
  snapshot_id       = data.aws_ssm_parameter.snapshot.value != "null" ? data.aws_ssm_parameter.snapshot.value : ""
  type              = local.solr_asg_props["ebs_type"]
  size              = local.solr_asg_props["ebs_size"]
  iops              = local.ebs_type == "gp2" ? 0 : local.ebs_iops
  tags = merge(
    local.tags,
    {
      "Name"               = local.common_name
      "CreateSnapshotSolr" = 1
    },
  )
}

resource "aws_ebs_volume" "solr_temp" {
  availability_zone = data.aws_subnet.selected.availability_zone
  encrypted         = true
  type              = local.solr_asg_props["ebs_temp_type"]
  size              = local.solr_asg_props["ebs_temp_size"]
  iops              = 0
  tags = merge(
    local.tags,
    {
      "Name"               = "${local.common_name}-temp"
      "CreateSnapshotSolr" = 1
    },
  )
}

# ############################################
# # CREATE USER DATA FOR EC2 RUNNING SERVICES
# ############################################

data "template_file" "user_data" {
  template = file("../user_data/solr_user_data.sh")

  vars = {
    env_identifier             = local.environment_identifier
    short_env_identifier       = local.short_environment_identifier
    app_name                   = local.alfresco_app_name
    cldwatch_log_group         = module.create_loggroup.loggroup_name
    region                     = var.region
    cache_home                 = "/srv/cache"
    ebs_device                 = "/dev/xvdb"
    app_name                   = local.alfresco_app_name
    route53_sub_domain         = "${local.alfresco_app_name}.${local.environment}"
    private_domain             = local.internal_domain
    private_zone_id            = local.private_zone_id
    account_id                 = local.account_id
    internal_domain            = local.internal_domain
    elasticsearch_url          = local.elasticsearch_props["url"]
    elasticsearch_cluster_name = local.elasticsearch_props["cluster_name"]
    cluster_subnet             = ""
    cluster_name               = "${local.environment_identifier}-public-ecs-cluster"
    db_name                    = local.db_name
    db_host                    = local.db_host
    db_user                    = local.db_username_ssm
    db_password                = local.db_password_ssm
    s3_bucket_config           = local.config-bucket
    ssm_get_command            = "aws --region ${var.region} ssm get-parameters --names"
    messaging_broker_url       = local.messaging_broker_url
    messaging_broker_password  = local.messaging_broker_password
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
    solr_version         = var.source_code_versions["solr"]
    # SOLR
    solr_port             = local.solr_port
    solr_device_name      = local.solr_asg_props["ebs_device_name"]
    solr_volume_name      = local.common_name
    solr_java_xms         = local.solr_asg_props["java_xms"]
    solr_java_xmx         = local.solr_asg_props["java_xmx"]
    jvm_memory            = local.solr_asg_props["alf_jvm_memory"]
    backups_bucket        = local.backups_bucket
    solr_temp_device_name = local.solr_asg_props["ebs_temp_device_name"]
    solr_temp_volume_name = "${local.common_name}-temp"
    solr_temp_dir         = "/tmp/solr"
    solr_cmis_managed     = var.solr_cmis_managed
  }
}

# ############################################
# # CREATE LAUNCH CONFIG FOR EC2 RUNNING SERVICES
# ############################################

resource "aws_launch_configuration" "environment" {
  name_prefix                 = "${local.common_name}-"
  image_id                    = local.ami_id
  instance_type               = local.solr_asg_props["instance_type"]
  iam_instance_profile        = data.terraform_remote_state.iam.outputs.solr_profile_name
  key_name                    = data.terraform_remote_state.common.outputs.common_ssh_deployer_key
  security_groups             = flatten(local.instance_security_groups)
  associate_public_ip_address = false
  user_data                   = data.template_file.user_data.rendered
  enable_monitoring           = true
  ebs_optimized               = false

  root_block_device {
    volume_type = "standard"
    volume_size = var.alfresco_volume_size
  }

  lifecycle {
    create_before_destroy = true
  }

  ebs_block_device {
    device_name           = "/dev/xvdb"
    volume_type           = "standard"
    volume_size           = lookup(var.alfresco_asg_props, "ebs_volume_size", 512)
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

resource "aws_autoscaling_group" "environment" {
  name                      = aws_launch_configuration.environment.name
  vpc_zone_identifier       = [data.aws_subnet.selected.id]
  min_size                  = var.restoring == "enabled" ? 0 : 1
  max_size                  = var.restoring == "enabled" ? 0 : 1
  desired_capacity          = var.restoring == "enabled" ? 0 : 1
  launch_configuration      = aws_launch_configuration.environment.name
  health_check_grace_period = 900
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
        value               = aws_launch_configuration.environment.name
        propagate_at_launch = true
      },
    ],
    data.null_data_source.tags.*.outputs
  )
}

