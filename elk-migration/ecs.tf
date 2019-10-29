############################################
# CREATE LOG GROUPS FOR CONTAINER LOGS
############################################

module "create_loggroup" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//cloudwatch//loggroup"
  log_group_path           = "${local.common_name}"
  loggroupname             = "${local.application}"
  cloudwatch_log_retention = "${var.alf_cloudwatch_log_retention}"
  kms_key_id               = "${local.logs_kms_arn}"
  tags                     = "${local.tags}"
}

############################################
# CREATE ECS CLUSTER
############################################

module "ecs_cluster" {
  source       = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//ecs//ecs_cluster"
  cluster_name = "${local.common_name}"

  tags = "${local.tags}"
}

############################################
# CREATE ECS TASK DEFINTIONS
############################################

data "template_file" "app_task_definition" {
  template = "${file("./task_definitions/elasticsearch.conf")}"

  vars {
    environment          = "${local.environment}"
    image_url            = "${local.image_url}"
    container_name       = "${local.application}"
    log_group_name       = "${module.create_loggroup.loggroup_name}"
    log_group_region     = "${local.region}"
    memory               = "${var.elk_migration_props["ecs_memory"]}"
    cpu_units            = "${var.elk_migration_props["ecs_cpu_units"]}"
    es_jvm_heap_size     = "${var.elk_migration_props["jvm_heap_size"]}"
    efs_mount_path       = "${local.efs_mount_path}"
    migration_mount_path = "${local.migration_mount_path}"
  }
}

resource "aws_ecs_task_definition" "environment" {
  family                = "${local.common_name}-task-definition"
  container_definitions = "${data.template_file.app_task_definition.rendered}"

  volume {
    name      = "backup"
    host_path = "${local.efs_mount_path}"
  }

  volume {
    name      = "local"
    host_path = "${local.migration_mount_path}"
  }

  volume {
    name      = "data"
    host_path = "${local.es_home_dir}/data"
  }

  volume {
    name      = "config"
    host_path = "${local.es_home_dir}/conf.d/elasticsearch.yml.tmpl"
  }
}

############################################
# CREATE ECS SERVICES
############################################

resource "aws_ecs_service" "elk_service" {
  name                               = "${local.common_name}-ecs-svc"
  cluster                            = "${module.ecs_cluster.ecs_cluster_id}"
  task_definition                    = "${aws_ecs_task_definition.environment.arn}"
  desired_count                      = "${local.service_desired_count}"
  iam_role                           = "${module.create-iam-ecs-role-int.iamrole_arn}"
  deployment_minimum_healthy_percent = 50

  load_balancer {
    target_group_arn = "${module.create_alb_target_grp.target_group_arn}"
    container_name   = "${local.application}"
    container_port   = "${local.port}"
  }

  depends_on = [
    "module.create_alb_target_grp",
    "module.create_app_alb",
    "module.create_alb_listener",
  ]
}
