resource "aws_lb" "alb" {
  name               = local.common_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = flatten(local.subnet_ids)

  enable_deletion_protection = false

  access_logs {
    bucket  = local.access_logs_bucket
    prefix  = local.common_name
    enabled = true
  }

  tags = merge(
    local.tags,
    {
      "Name" = local.common_name
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "dns_entry" {
  zone_id = local.public_zone_id
  name    = local.dns_hostname
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = false
  }
}
