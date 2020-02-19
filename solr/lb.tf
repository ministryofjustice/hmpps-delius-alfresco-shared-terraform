locals {
  http_port      = 80
  http_protocol  = "HTTP"
  https_port     = 443
  https_protocol = "HTTPS"

}

############################################
# CREATE LB FOR SOLR
############################################

# alb
resource "aws_lb" "environment" {
  name               = "${local.common_name}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.sg_solr_alb.id}"]
  subnets            = ["${local.private_subnet_ids}"]

  enable_deletion_protection = false

  access_logs {
    bucket  = "${local.access_logs_bucket}"
    prefix  = "${local.common_name}"
    enabled = true
  }

  tags = "${merge(local.tags, map("Name", "${local.common_name}"))}"

  lifecycle {
    create_before_destroy = true
  }
}

###############################################
# Create route53 entry for solr lb
###############################################

resource "aws_route53_record" "dns_entry" {
  zone_id = "${local.public_zone_id}"
  name    = "${var.alf_solr_config["solr_host"]}.${local.external_domain}"
  type    = "A"

  alias {
    name                   = "${aws_lb.environment.dns_name}"
    zone_id                = "${aws_lb.environment.zone_id}"
    evaluate_target_health = false
  }
}

# listener
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = "${aws_lb.environment.arn}"
  port              = "${local.http_port}"
  protocol          = "${local.http_protocol}"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

}

module "https_listener" {
  source           = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//loadbalancer//alb/create_listener_with_https"
  lb_arn           = "${aws_lb.environment.arn}"
  lb_port          = 443
  lb_protocol      = "${local.https_protocol}"
  target_group_arn = "${aws_lb_target_group.environment.arn}"
  certificate_arn  = ["${local.certificate_arn}"]
}

# target group

resource "aws_lb_target_group" "environment" {
  name                 = "${local.common_name}"
  port                 = "${local.solr_port}"
  protocol             = "${local.http_protocol}"
  vpc_id               = "${local.vpc_id}"
  deregistration_delay = 120
  target_type          = "instance"

  health_check {
    interval            = 30
    path                = "/solr/"
    port                = "${local.solr_port}"
    protocol            = "${local.http_protocol}"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-299"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = "${var.cookie_duration}"
    enabled         = true
  }

  tags = "${merge(local.tags, map("Name", "${local.common_name}"))}"
}
