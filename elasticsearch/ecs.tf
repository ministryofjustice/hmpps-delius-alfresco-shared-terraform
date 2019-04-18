locals {
  efs_mount_path = "/opt/esbackup"
  efs_share_id   = "${data.terraform_remote_state.efs.efs_id}"
  es_home_dir    = "/opt/elasticsearch"
}

############################################
# CREATE LB FOR NGINX
############################################

# elb
module "create_app_elb" {
  source          = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//loadbalancer//elb//create_elb_with_https"
  name            = "${local.common_name}"
  subnets         = ["${local.private_subnet_ids}"]
  security_groups = ["${local.lb_security_groups}"]
  internal        = true

  cross_zone_load_balancing   = "${var.cross_zone_load_balancing}"
  idle_timeout                = "${var.idle_timeout}"
  connection_draining         = "${var.connection_draining}"
  connection_draining_timeout = "${var.connection_draining_timeout}"
  bucket                      = "${local.access_logs_bucket}"
  bucket_prefix               = "${local.common_name}"
  interval                    = 60
  ssl_certificate_id          = "${local.certificate_arn}"
  instance_port               = 9200
  instance_protocol           = "http"
  lb_port                     = 80
  lb_port_https               = 443
  lb_protocol                 = "http"
  lb_protocol_https           = "https"

  health_check = [
    {
      target              = "HTTP:9200/"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]

  tags = "${local.tags}"
}

###############################################
# Create route53 entry lb
###############################################

resource "aws_route53_record" "dns_entry" {
  zone_id = "${local.public_zone_id}"
  name    = "alf-es.${local.external_domain}"
  type    = "A"

  alias {
    name                   = "${module.create_app_elb.environment_elb_dns_name}"
    zone_id                = "${module.create_app_elb.environment_elb_zone_id}"
    evaluate_target_health = false
  }
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
# CREATE LOG GROUPS FOR CONTAINER LOGS
############################################

module "create_loggroup" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//cloudwatch//loggroup"
  log_group_path           = "${local.common_name}"
  loggroupname             = "${local.application}"
  cloudwatch_log_retention = "${var.cloudwatch_log_retention}"
  tags                     = "${local.tags}"
}

############################################
# CREATE ECS TASK DEFINTIONS
############################################

data "aws_ecs_task_definition" "app_task_definition" {
  task_definition = "${aws_ecs_task_definition.environment.family}"
  depends_on      = ["aws_ecs_task_definition.environment"]
}

data "template_file" "app_task_definition" {
  template = "${file("../task_definitions/elasticsearch.conf")}"

  vars {
    environment      = "${local.environment}"
    image_url        = "${local.image_url}"
    container_name   = "${local.application}"
    log_group_name   = "${module.create_loggroup.loggroup_name}"
    log_group_region = "${local.region}"
    memory           = "${var.es_ecs_memory}"
    cpu_units        = "${var.es_ecs_cpu_units}"
    es_java_opts     = "${var.es_java_opts}"
    mem_limit        = "${var.es_ecs_mem_limit}"
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
    name      = "config"
    host_path = "${local.es_home_dir}/config/elasticsearch.yml"
  }

  volume {
    name      = "data"
    host_path = "${local.es_home_dir}/data"
  }
}

############################################
# CREATE ECS SERVICES
############################################

module "app_service" {
  source                          = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//ecs/ecs_service//withloadbalancer//elb"
  servicename                     = "${local.common_name}"
  clustername                     = "${module.ecs_cluster.ecs_cluster_id}"
  ecs_service_role                = "${local.ecs_service_role}"
  task_definition_family          = "${aws_ecs_task_definition.environment.family}"
  task_definition_revision        = "${aws_ecs_task_definition.environment.revision}"
  current_task_definition_version = "${data.aws_ecs_task_definition.app_task_definition.revision}"
  service_desired_count           = "${local.service_desired_count}"
  elb_name                        = "${module.create_app_elb.environment_elb_name}"
  containername                   = "${local.application}"
  containerport                   = 9200
}

#-------------------------------------------------------------
### Create ecs  
#-------------------------------------------------------------

data "template_file" "userdata_ecs" {
  template = "${file("../user_data/ecs.sh")}"

  vars {
    app_name             = "${local.application}"
    bastion_inventory    = "${local.bastion_inventory}"
    env_identifier       = "${local.environment_identifier}"
    short_env_identifier = "${local.short_environment_identifier}"
    environment_name     = "${var.environment_name}"
    private_domain       = "${local.internal_domain}"
    account_id           = "${local.account_id}"
    internal_domain      = "${local.internal_domain}"
    environment          = "${local.environment}"
    common_name          = "${local.common_name}"
    ecs_cluster          = "${module.ecs_cluster.ecs_cluster_name}"
    efs_share_id         = "${local.efs_share_id}"
    efs_mount_path       = "${local.efs_mount_path}"
    es_home_dir          = "${local.es_home_dir}"
  }
}

############################################
# CREATE LAUNCH CONFIG FOR EC2 RUNNING SERVICES
############################################

module "launch_cfg" {
  source                      = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//launch_configuration//blockdevice"
  launch_configuration_name   = "${local.common_label}-az1"
  image_id                    = "${data.aws_ami.ecs_ami.id}"
  instance_type               = "t2.large"
  volume_size                 = "30"
  instance_profile            = "${local.instance_profile}"
  key_name                    = "${local.ssh_deployer_key}"
  ebs_device_name             = "/dev/xvdb"
  ebs_encrypted               = "true"
  ebs_volume_size             = "${var.es_ebs_volume_size}"
  ebs_volume_type             = "standard"
  associate_public_ip_address = false
  security_groups             = ["${local.instance_security_groups}"]
  user_data                   = "${data.template_file.userdata_ecs.rendered}"
}

# ############################################
# # CREATE AUTO SCALING GROUP
# ############################################

#AZ1
module "auto_scale_az1" {
  source               = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//autoscaling//group//asg_classic_lb"
  asg_name             = "${local.common_name}-az1"
  subnet_ids           = ["${local.private_subnet_ids[0]}"]
  asg_min              = 1
  asg_max              = 1
  asg_desired          = 1
  launch_configuration = "${module.launch_cfg.launch_name}"
  load_balancers       = []
  tags                 = "${local.tags}"
}
