############################################
# CREATE LB FOR INGRESS NODE
############################################

# alb
module "create_app_alb" {
  source          = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//loadbalancer//alb/create_lb"
  lb_name         = "${local.common_name}"
  subnet_ids      = ["${local.private_subnet_ids}"]
  security_groups = ["${local.lb_security_groups}"]
  internal        = true
  s3_bucket_name  = "${local.access_logs_bucket}"
  tags            = "${local.tags}"
}

# target group
module "create_alb_target_grp" {
  source              = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//loadbalancer//alb/targetgroup"
  appname             = "${local.common_name}"
  target_port         = "${local.port}"
  target_protocol     = "${local.protocol}"
  vpc_id              = "${local.vpc_id}"
  target_type         = "instance"
  tags                = "${local.tags}"
  check_interval      = "30"
  check_path          = "/_cat/health"
  check_port          = "${local.port}"
  check_protocol      = "${local.protocol}"
  timeout             = 5
  healthy_threshold   = 3
  unhealthy_threshold = 3
  return_code         = "200-299"
}

# listener
module "create_alb_listener" {
  source           = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//loadbalancer//alb/create_listener"
  lb_arn           = "${module.create_app_alb.lb_arn}"
  lb_port          = "${local.port}"
  lb_protocol      = "${local.protocol}"
  target_group_arn = "${module.create_alb_target_grp.target_group_arn}"
}

# ############################################
# ROUTE53
# ############################################
resource "aws_route53_record" "internal_migration_dns" {
  name    = "${local.application}.${local.internal_domain}"
  type    = "A"
  zone_id = "${local.private_zone_id}"

  alias {
    name                   = "${module.create_app_alb.lb_dns_name}"
    zone_id                = "${module.create_app_alb.lb_zone_id}"
    evaluate_target_health = false
  }
}
