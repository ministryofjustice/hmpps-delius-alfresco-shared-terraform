locals {
  kibana_port           = 5601
  kibana_protocol       = "HTTP"
  kibana_container_name = "kibana"
  kibana_image_url      = lookup(local.alf_elk_service_props, "kibana_image_url", "docker.elastic.co/kibana/kibana-oss:6.8.9")
  es_host_protocol      = lookup(local.alf_elk_service_props, "es_host_protocol", "https")
  es_host_port          = lookup(local.alf_elk_service_props, "es_host_port", 443)
  es_url                = "${local.es_host_protocol}://${aws_elasticsearch_domain.es.endpoint}:${local.es_host_port}"
}

# alb
module "kibana_alb" {
  source          = "../modules/loadbalancer/alb/create_lb"
  lb_name         = local.common_name
  subnet_ids      = flatten(local.public_subnet_ids)
  security_groups = [aws_security_group.lb.id]
  internal        = false
  s3_bucket_name  = local.access_logs_bucket
  tags            = local.tags
}

resource "aws_route53_record" "kibana_dns" {
  name    = local.kibana_host_fqdn
  type    = "A"
  zone_id = local.public_zone_id

  alias {
    name                   = module.kibana_alb.lb_dns_name
    zone_id                = module.kibana_alb.lb_zone_id
    evaluate_target_health = false
  }
}

# target group
module "kibana_target_grp" {
  source              = "../modules/loadbalancer/alb/targetgroup"
  appname             = "${local.application}-kb"
  target_port         = local.kibana_port
  target_protocol     = local.kibana_protocol
  vpc_id              = local.vpc_id
  target_type         = "ip"
  tags                = local.tags
  check_interval      = "30"
  check_path          = "/api/status"
  check_port          = local.kibana_port
  check_protocol      = local.kibana_protocol
  timeout             = 5
  healthy_threshold   = 3
  unhealthy_threshold = 3
  return_code         = "200-299"
}

# listener
resource "aws_lb_listener" "kibana_https" {
  load_balancer_arn = module.kibana_alb.lb_arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = lookup(local.alf_elk_service_props, "ssl_policy", "ELBSecurityPolicy-TLS-1-2-2017-01")
  certificate_arn   = local.certificate_arn

  default_action {
    target_group_arn = module.kibana_target_grp.target_group_arn
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "kibana_cognito" {
  listener_arn = aws_lb_listener.kibana_https.arn

  action {
    type = "authenticate-cognito"

    authenticate_cognito {
      user_pool_arn       = aws_cognito_user_pool.pool.arn
      user_pool_client_id = aws_cognito_user_pool_client.client.id
      user_pool_domain    = aws_cognito_user_pool_domain.pool.domain
    }
  }

  action {
    type             = "forward"
    target_group_arn = module.kibana_target_grp.target_group_arn
  }

  condition {
    path_pattern {
      values = ["/app/kibana*"]
    }
  }
}

resource "aws_lb_listener" "kibana" {
  load_balancer_arn = module.kibana_alb.lb_arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

############################################
# CREATE LOG GROUPS FOR CONTAINER LOGS
############################################

module "kibana_loggroup" {
  source                   = "../modules/cloudwatch/loggroup"
  log_group_path           = local.common_name
  loggroupname             = local.kibana_container_name
  cloudwatch_log_retention = var.alf_cloudwatch_log_retention
  kms_key_id               = local.logs_kms_arn
  tags                     = local.tags
}

############################################
# CREATE ECS TASK DEFINTIONS
############################################

resource "aws_ecs_task_definition" "kibana" {
  family                   = "${local.common_name}-${local.kibana_container_name}"
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  tags = merge(
    local.tags,
    {
      "Name" = "${local.common_name}-${local.kibana_container_name}"
    }
  )
  container_definitions = templatefile(
    "${path.module}/task_definitions/kibana.conf",
    {
      kibana_image_url = local.kibana_image_url
      container_name   = local.kibana_container_name
      log_group_region = local.region
      kibana_loggroup  = module.kibana_loggroup.loggroup_name
      es_host          = local.es_url
    }
  )
}

resource "aws_ecs_service" "kibana_service" {
  name                               = "${local.common_name}-${local.kibana_container_name}"
  cluster                            = local.ecs_cluster_name
  task_definition                    = aws_ecs_task_definition.kibana.arn
  desired_count                      = lookup(local.alf_elk_service_props, "desired_count", 2)
  deployment_minimum_healthy_percent = 50
  network_configuration {
    security_groups = [
      aws_security_group.kibana.id,
      data.terraform_remote_state.common.outputs.common_sg_outbound_id
    ]
    subnets = flatten(local.private_subnet_ids)
  }

  service_registries {
    registry_arn = aws_service_discovery_service.kibana.arn
  }

  load_balancer {
    target_group_arn = module.kibana_target_grp.target_group_arn
    container_name   = local.kibana_container_name
    container_port   = local.kibana_port
  }
}

resource "aws_launch_configuration" "kibana" {
  name_prefix                 = "${local.common_name}-${local.kibana_container_name}"
  associate_public_ip_address = false
  iam_instance_profile        = module.create-iam-instance-profile-es.iam_instance_name
  image_id                    = data.aws_ami.aws_ecs_ami.id
  instance_type               = lookup(local.alf_elk_service_props, "kibana_instance_type", "t2.medium")
  key_name                    = local.ssh_deployer_key
  security_groups = [
    aws_security_group.kibana.id,
    data.terraform_remote_state.common.outputs.common_sg_outbound_id,
    data.terraform_remote_state.network-security-groups.outputs.sg_ssh_bastion_in_id
  ]
  user_data = templatefile(
    "${path.module}/user_data/userdata_amazonlinux.sh",
    {
      svc_name        = local.common_name
      es_cluster_name = local.ecs_cluster_name
      log_group_name  = module.kibana_loggroup.loggroup_name
      region          = var.region
    }
  )
  root_block_device {
    volume_type = lookup(local.alf_elk_service_props, "root_volume_type", "standard")
    volume_size = lookup(local.alf_elk_service_props, "root_volume_size", 60)
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "null_data_source" "tags" {
  count = length(keys(local.tags))

  inputs = {
    key                 = element(keys(local.tags), count.index)
    value               = element(values(local.tags), count.index)
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "kibana" {
  name                      = aws_launch_configuration.kibana.name
  vpc_zone_identifier       = flatten(local.private_subnet_ids)
  min_size                  = lookup(local.alf_elk_service_props, "kibana_asg_size", 2)
  max_size                  = lookup(local.alf_elk_service_props, "kibana_asg_size", 2)
  desired_capacity          = lookup(local.alf_elk_service_props, "kibana_asg_size", 2)
  launch_configuration      = aws_launch_configuration.kibana.name
  health_check_grace_period = 300
  termination_policies      = var.termination_policies
  health_check_type         = var.health_check_type
  metrics_granularity       = var.metrics_granularity
  enabled_metrics           = var.enabled_metrics

  lifecycle {
    create_before_destroy = true
  }

  tags = concat(
    [
      {
        key                 = "Name"
        value               = "${local.common_name}-${local.kibana_container_name}"
        propagate_at_launch = true
      },
    ],
    data.null_data_source.tags.*.outputs
  )
}
