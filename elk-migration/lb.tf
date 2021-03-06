############################################
# CREATE LB FOR INGRESS NODE
############################################

# alb
module "create_app_alb" {
  source          = "../modules/loadbalancer/alb/create_lb"
  lb_name         = local.common_name
  subnet_ids      = flatten(local.private_subnet_ids)
  security_groups = flatten(local.lb_security_groups)
  internal        = true
  s3_bucket_name  = local.access_logs_bucket
  tags            = local.tags
}

# target group
module "create_alb_target_grp" {
  source              = "../modules/loadbalancer/alb/targetgroup"
  appname             = local.common_name
  target_port         = local.port
  target_protocol     = local.protocol
  vpc_id              = local.vpc_id
  target_type         = "instance"
  tags                = local.tags
  check_interval      = "30"
  check_path          = "/_cat/health"
  check_port          = local.port
  check_protocol      = local.protocol
  timeout             = 5
  healthy_threshold   = 3
  unhealthy_threshold = 3
  return_code         = "200-299"
}

# listener
module "create_alb_listener" {
  source           = "../modules/loadbalancer/alb/create_listener_with_https"
  lb_arn           = module.create_app_alb.lb_arn
  lb_port          = 443
  lb_protocol      = "HTTPS"
  target_group_arn = module.create_alb_target_grp.target_group_arn
  certificate_arn  = local.certificate_arn
}

module "alt_https_listener" {
  source           = "../modules/loadbalancer/alb/create_listener_with_https"
  lb_arn           = module.create_app_alb.lb_arn
  lb_port          = local.port
  lb_protocol      = "HTTPS"
  target_group_arn = module.create_alb_target_grp.target_group_arn
  certificate_arn  = local.certificate_arn
}

resource "aws_lb_listener" "es" {
  load_balancer_arn = module.create_app_alb.lb_arn
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

# ############################################
# ROUTE53
# ############################################
resource "aws_route53_record" "internal_migration_dns" {
  name    = "${local.application}.${local.internal_domain}"
  type    = "A"
  zone_id = local.private_zone_id

  alias {
    name                   = module.create_app_alb.lb_dns_name
    zone_id                = module.create_app_alb.lb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "public_es_dns" {
  name    = local.es_host_fqdn
  type    = "A"
  zone_id = local.public_zone_id

  alias {
    name                   = module.create_app_alb.lb_dns_name
    zone_id                = module.create_app_alb.lb_zone_id
    evaluate_target_health = false
  }
}

