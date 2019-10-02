locals {
  kibana_port           = 5601
  kibana_protocol       = "HTTP"
  kibana_container_name = "kibana"
  target_grp_name       = "${var.kibana_short_name != "" ? var.kibana_short_name : local.kibana_container_name}"
  kibana_image_url      = "${var.elk_migration_props["kibana_image_url"]}"
}

# target group
module "kibana_target_grp" {
  source              = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//loadbalancer//alb/targetgroup"
  appname             = "${local.common_name}-${local.target_grp_name}"
  target_port         = "${local.kibana_port}"
  target_protocol     = "${local.kibana_protocol}"
  vpc_id              = "${local.vpc_id}"
  target_type         = "instance"
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
module "kibana_alb_listener" {
  source           = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//loadbalancer//alb/create_listener_with_https"
  lb_arn           = "${module.create_app_alb.lb_arn}"
  lb_port          = 443
  lb_protocol      = "HTTPS"
  target_group_arn = "${module.kibana_target_grp.target_group_arn}"
  certificate_arn  = ["${local.certificate_arn}"]
}

############################################
# CREATE LOG GROUPS FOR CONTAINER LOGS
############################################

module "kibana_loggroup" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//cloudwatch//loggroup"
  log_group_path           = "${local.common_name}"
  loggroupname             = "${local.kibana_container_name}"
  cloudwatch_log_retention = "${var.cloudwatch_log_retention}"
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
    es_host_url      = "${aws_route53_record.internal_migration_dns.fqdn}"
    server_name      = "${local.common_name}-${local.kibana_container_name}"
  }
}

resource "aws_ecs_task_definition" "kibana" {
  family                = "${local.kibana_container_name}-task-definition"
  container_definitions = "${data.template_file.kibana.rendered}"
}


resource "aws_ecs_service" "kibana_service" {
  name                               = "${local.common_name}-${local.kibana_container_name}"
  cluster                            = "${module.ecs_cluster.ecs_cluster_id}"
  task_definition                    = "${aws_ecs_task_definition.kibana.arn}"
  desired_count                      = 2
  iam_role                           = "${module.create-iam-ecs-role-int.iamrole_arn}"
  deployment_minimum_healthy_percent = 50

  load_balancer {
    target_group_arn = "${module.kibana_target_grp.target_group_arn}"
    container_name   = "${local.kibana_container_name}"
    container_port   = "${local.kibana_port}"
  }
}
