locals {
  logstash_containerports = {
    http = 9600
    logs = 2514
  }
  service_type       = "logstash"
  logstash_image_url = "${var.elk_migration_props["logstash_image_url"]}"
}

############################################
# CREATE LB FOR INGRESS NODE
############################################

# elb

resource "aws_elb" "mon_lb" {
  name            = "${local.common_name}-mon"
  subnets         = ["${local.private_subnet_ids}"]
  security_groups = ["${local.lb_security_groups}"]
  internal        = true

  cross_zone_load_balancing   = true
  idle_timeout                = 60
  connection_draining         = false
  connection_draining_timeout = 300

  listener {
    instance_port     = "${local.logstash_containerports["logs"]}"
    instance_protocol = "tcp"
    lb_port           = "${local.logstash_containerports["logs"]}"
    lb_protocol       = "tcp"
  }

  access_logs = {
    bucket        = "${local.access_logs_bucket}"
    bucket_prefix = "${local.common_name}-mon"
    interval      = 60
  }

  health_check = [
    {
      target              = "TCP:${local.logstash_containerports["logs"]}"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]

  tags = "${merge(local.tags, map("Name", format("%s", "${local.common_name}-mon")))}"
}

# logstash
resource "aws_route53_record" "internal_logstash_dns" {
  zone_id = "${local.private_zone_id}"
  name    = "migration_logstash.${local.internal_domain}"
  type    = "A"

  alias {
    name                   = "${aws_elb.mon_lb.dns_name}"
    zone_id                = "${aws_elb.mon_lb.zone_id}"
    evaluate_target_health = false
  }
}

############################################
# CREATE LOG GROUPS FOR CONTAINER LOGS
############################################

module "logstash_loggroup" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//cloudwatch//loggroup"
  log_group_path           = "${local.common_name}"
  loggroupname             = "logstash"
  cloudwatch_log_retention = "${var.cloudwatch_log_retention}"
  tags                     = "${local.tags}"
}

module "redis_loggroup" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//cloudwatch//loggroup"
  log_group_path           = "${local.common_name}"
  loggroupname             = "redis"
  cloudwatch_log_retention = "${var.cloudwatch_log_retention}"
  tags                     = "${local.tags}"
}

############################################
# CREATE ECS TASK DEFINTIONS
############################################
data "template_file" "logstash" {
  template = "${file("./task_definitions/logstash.conf")}"

  vars {
    logstash_loggroup  = "${module.logstash_loggroup.loggroup_name}"
    redis_loggroup     = "${module.redis_loggroup.loggroup_name}"
    log_group_region   = "${local.region}"
    logstash_image_url = "${local.logstash_image_url}"
    es_host_url        = "${aws_route53_record.internal_migration_dns.fqdn}"
  }
}

resource "aws_ecs_task_definition" "logstash" {
  family                = "${local.common_name}-${local.service_type}"
  container_definitions = "${data.template_file.logstash.rendered}"

  volume {
    name      = "confd"
    host_path = "${local.es_home_dir}/conf.d/logstash.conf.tmpl"
  }
}

############################################
# CREATE ECS SERVICES
############################################

resource "aws_ecs_service" "environment" {
  name                               = "${local.common_name}-${local.service_type}"
  cluster                            = "${module.ecs_cluster.ecs_cluster_id}"
  task_definition                    = "${aws_ecs_task_definition.logstash.arn}"
  desired_count                      = 2
  iam_role                           = "${module.create-iam-ecs-role-int.iamrole_arn}"
  deployment_minimum_healthy_percent = 50

  load_balancer {
    elb_name       = "${aws_elb.mon_lb.name}"
    container_name = "${local.service_type}"
    container_port = "${local.logstash_containerports["logs"]}"
  }
}
