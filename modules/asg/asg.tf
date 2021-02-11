# ############################################
# # CREATE USER DATA FOR EC2 RUNNING SERVICES
# ############################################

data "template_file" "user_data" {
  template = file(var.user_data)

  vars = {
    env_identifier             = var.environment_identifier
    short_env_identifier       = var.short_environment_identifier
    app_name                   = var.alfresco_app_name
    cldwatch_log_group         = module.create_loggroup.loggroup_name
    region                     = var.region
    cache_home                 = var.cache_home
    ebs_device                 = var.ebs_device_name
    app_name                   = var.alfresco_app_name
    route53_sub_domain         = "${var.alfresco_app_name}.${var.environment}"
    private_domain             = var.internal_domain
    account_id                 = var.account_id
    internal_domain            = var.internal_domain
    elasticsearch_url          = var.elasticsearch_props["url"]
    elasticsearch_cluster_name = var.elasticsearch_props["cluster_name"]
    cluster_subnet             = ""
    cluster_name               = "${var.environment_identifier}-public-ecs-cluster"
    db_name                    = local.db_name
    db_host                    = local.db_host
    db_user                    = local.db_username
    db_password                = local.db_password
    keys_dir                   = var.keys_dir
    tomcat_host                = var.tomcat_host
    tomcat_port                = var.tomcat_port
    config_file_path           = "${local.common_name}/config/nginx.conf"
    nginx_config_file          = "/etc/nginx/conf.d/app.conf"
    s3_bucket_config           = local.config_bucket
    runtime_config_override    = "s3"
    ssm_get_command            = "aws --region ${var.region} ssm get-parameters --names"
    messaging_broker_url       = var.messaging_broker_url
    messaging_broker_password  = local.messaging_broker_password
    #s3 config data
    bucket_name         = var.alfresco_s3bucket
    bucket_encrypt_type = "kms"
    bucket_key_id       = var.bucket_kms_key_id
    external_fqdn       = "${var.app_hostnames["external"]}.${var.external_domain}"
    jvm_memory          = var.jvm_memory
    # For bootstrapping
    bastion_inventory    = var.bastion_inventory
    bootstrap_version    = var.source_code_versions["boostrap"]
    alfresco_version     = var.source_code_versions["alfresco"]
    logstash_version     = var.source_code_versions["logstash"]
    elasticbeats_version = var.source_code_versions["elasticbeats"]
    # SOLR
    solr_host = var.solr_config["solr_host"]
    solr_port = var.solr_config["solr_port"]
    solr_cmis_managed    = var.solr_cmis_managed
  }
}

# ############################################
# # CREATE LAUNCH CONFIG FOR EC2 RUNNING SERVICES
# ############################################

resource "aws_launch_configuration" "environment" {
  name_prefix                 = "asg-alf-"
  image_id                    = var.ami_id
  instance_type               = var.instance_type
  iam_instance_profile        = var.instance_profile
  key_name                    = var.ssh_deployer_key
  security_groups             = flatten(local.instance_security_groups)
  associate_public_ip_address = var.associate_public_ip_address
  user_data                   = data.template_file.user_data.rendered
  enable_monitoring           = true
  ebs_optimized               = var.ebs_optimized

  root_block_device {
    volume_type = var.volume_type
    volume_size = var.volume_size
  }

  lifecycle {
    create_before_destroy = true
  }

  ebs_block_device {
    device_name           = var.ebs_device_name
    volume_type           = var.ebs_volume_type
    volume_size           = var.ebs_volume_size
    encrypted             = var.ebs_encrypted
    delete_on_termination = var.ebs_delete_on_termination
  }
}

# ############################################
# # CREATE AUTO SCALING GROUP
# ############################################
resource "aws_placement_group" "environment" {
  name     = "${local.common_prefix}-pg"
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
  name                      = "${local.common_prefix}-${aws_launch_configuration.environment.name}"
  vpc_zone_identifier       = flatten(local.subnet_ids)
  min_size                  = var.az_asg_min
  max_size                  = var.az_asg_max
  desired_capacity          = var.az_asg_desired
  launch_configuration      = aws_launch_configuration.environment.name
  health_check_grace_period = var.health_check_grace_period
  placement_group           = aws_placement_group.environment.id
  target_group_arns         = [aws_lb_target_group.environment.arn]
  termination_policies      = var.termination_policies
  health_check_type         = var.health_check_type
  metrics_granularity       = var.metrics_granularity
  enabled_metrics           = var.enabled_metrics
  min_elb_capacity          = var.min_elb_capacity
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  default_cooldown          = var.default_cooldown

  lifecycle {
    create_before_destroy = true
  }
  tags = concat(
    [
      {
        key                 = "Name"
        value               = "${local.common_prefix}-${aws_launch_configuration.environment.name}"
        propagate_at_launch = true
      },
    ],
    data.null_data_source.tags.*.outputs
  )
}

