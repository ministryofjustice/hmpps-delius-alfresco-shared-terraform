locals {
  kibana_port           = 5601
  kibana_protocol       = "HTTP"
  kibana_container_name = "kibana"
  target_grp_name       = "${var.kibana_short_name != "" ? var.kibana_short_name : local.kibana_container_name}"
  kibana_image_url      = "${var.elk_migration_props["kibana_image_url"]}"
}

# lb
# alb
module "kibana_app_alb" {
  source          = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//loadbalancer//alb/create_lb"
  lb_name         = "${local.common_name}-kib"
  subnet_ids      = ["${local.public_subnet_ids}"]
  security_groups = ["${local.external_lb_sgs}"]
  internal        = false
  s3_bucket_name  = "${local.access_logs_bucket}"
  tags            = "${local.tags}"
}

# ############################################
# ROUTE53
# ############################################
resource "aws_route53_record" "kibana_migration_dns" {
  name    = "${local.kibana_host_fqdn}"
  type    = "A"
  zone_id = "${local.public_zone_id}"

  alias {
    name                   = "${module.kibana_app_alb.lb_dns_name}"
    zone_id                = "${module.kibana_app_alb.lb_zone_id}"
    evaluate_target_health = false
  }
}

# target group
module "kibana_target_grp" {
  source              = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//loadbalancer//alb/targetgroup"
  appname             = "${local.common_name}-${local.target_grp_name}"
  target_port         = "${local.kibana_port}"
  target_protocol     = "${local.kibana_protocol}"
  vpc_id              = "${local.vpc_id}"
  target_type         = "ip"
  tags                = "${local.tags}"
  check_interval      = "30"
  check_path          = "/api/status"
  check_port          = "${local.kibana_port}"
  check_protocol      = "${local.kibana_protocol}"
  timeout             = 5
  healthy_threshold   = 3
  unhealthy_threshold = 3
  return_code         = "200-299"
}

# listener
resource "aws_lb_listener" "kibana_https" {
  load_balancer_arn = "${module.kibana_app_alb.lb_arn}"
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "${var.elk_migration_props["ssl_policy"]}"
  certificate_arn   = "${local.certificate_arn}"

  default_action {
    target_group_arn = "${module.kibana_target_grp.target_group_arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "kibana_cognito" {
  listener_arn = "${aws_lb_listener.kibana_https.arn}"

  action {
    type = "authenticate-cognito"

    authenticate_cognito {
      user_pool_arn       = "${aws_cognito_user_pool.pool.arn}"
      user_pool_client_id = "${aws_cognito_user_pool_client.client.id}"
      user_pool_domain    = "${aws_cognito_user_pool_domain.pool.domain}"
    }
  }

  action {
    type             = "forward"
    target_group_arn = "${module.kibana_target_grp.target_group_arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/app/kibana*"]
  }
}

resource "aws_lb_listener" "kibana" {
  load_balancer_arn = "${module.kibana_app_alb.lb_arn}"
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
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//cloudwatch//loggroup"
  log_group_path           = "${local.common_name}"
  loggroupname             = "${local.kibana_container_name}"
  cloudwatch_log_retention = "${var.alf_cloudwatch_log_retention}"
  kms_key_id               = "${local.logs_kms_arn}"
  tags                     = "${local.tags}"
}

############################################
# CREATE ECS TASK DEFINTIONS
############################################

data "template_file" "kibana" {
  template = "${file("./task_definitions/kibana.conf")}"

  vars {
    kibana_image_url = "${local.kibana_image_url}"
    container_name   = "${local.kibana_container_name}"
    log_group_region = "${local.region}"
    kibana_loggroup  = "${module.kibana_loggroup.loggroup_name}"
    es_host_url      = "${local.es_host_url}"
    server_name      = "${local.common_name}"
    es_cluster_name  = "${local.common_name}"
  }
}

resource "aws_ecs_task_definition" "kibana" {
  family                   = "${local.common_name}-${local.kibana_container_name}"
  container_definitions    = "${data.template_file.kibana.rendered}"
  task_role_arn            = "${aws_iam_role.task.arn}"
  execution_role_arn       = "${aws_iam_role.execution.arn}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  tags                     = "${merge(local.tags, map("Name", "${local.common_name}-kibana"))}"
  volume {
    name      = "config"
    host_path = "/opt/kibana/supervisord.conf"
  }
  volume {
    name      = "data"
    host_path = "/efs/kibana/data"
  }
}

resource "aws_ecs_service" "kibana_service" {
  name                               = "${local.common_name}-${local.kibana_container_name}"
  cluster                            = "${module.ecs_cluster.ecs_cluster_id}"
  task_definition                    = "${aws_ecs_task_definition.kibana.arn}"
  desired_count                      = "${var.elk_migration_props["kibana_desired_count"]}"
  deployment_minimum_healthy_percent = 50
  network_configuration {
    security_groups = ["${local.instance_security_groups}"]
    subnets         = ["${local.private_subnet_ids}"]
  }

  service_registries {
    registry_arn = "${aws_service_discovery_service.kibana.arn}"
  }

  load_balancer {
    target_group_arn = "${module.kibana_target_grp.target_group_arn}"
    container_name   = "${local.kibana_container_name}"
    container_port   = "${local.kibana_port}"
  }
}

# launch config
data "template_file" "kibana_ecs" {
  template = "${file("../user_data/ecs_userdata_amazonlinux.sh")}"

  vars {
    efs_endpoint           = "${aws_efs_file_system.efs.dns_name}"
    efs_mount_path         = "${local.efs_mount_path}"
    es_cluster_name        = "${module.ecs_cluster.ecs_cluster_name}"
    es_home_dir            = "${local.es_home_dir}"
    es_host_url            = "${local.es_host_url}"
    es_master_nodes        = "${var.elk_migration_props["es_master_nodes"]}"
    log_group_name         = "${module.kibana_loggroup.loggroup_name}"
    migration_mount_path   = "${local.migration_mount_path}"
    region                 = "${var.region}"
    elk_user               = "${local.elk_user}"
    elk_password           = "${local.elk_password}"
    service_discovery_host = "kibana.${local.service_discovery_domain}"
  }
}

resource "aws_launch_configuration" "kibana" {
  name_prefix                 = "${local.common_name}-kibana"
  associate_public_ip_address = false
  iam_instance_profile        = "${module.create-iam-instance-profile-es.iam_instance_name}"
  image_id                    = "${data.aws_ami.aws_ecs_ami.id}"
  instance_type               = "${var.elk_migration_props["kibana_instance_type"]}"
  key_name                    = "${local.ssh_deployer_key}"
  security_groups             = ["${local.instance_security_groups}"]
  user_data                   = "${data.template_file.kibana_ecs.rendered}"
  # user_data_base64            = "${base64encode(data.template_file.kibana_ecs.rendered)}"
  root_block_device {
    volume_type = "${var.volume_type}"
    volume_size = 60
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "kibana" {
  name                      = "${local.common_name}-kibana"
  vpc_zone_identifier       = ["${local.private_subnet_ids}"]
  min_size                  = "${var.elk_migration_props["kibana_asg_size"]}"
  max_size                  = "${var.elk_migration_props["kibana_asg_size"]}"
  desired_capacity          = "${var.elk_migration_props["kibana_asg_size"]}"
  launch_configuration      = "${aws_launch_configuration.kibana.name}"
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
      value               = "${local.common_name}-kibana"
      propagate_at_launch = true
    },
  ]
}
