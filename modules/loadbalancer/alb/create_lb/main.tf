resource "aws_lb" "environment" {
  name               = "${var.lb_name}-lb"
  internal           = var.internal
  load_balancer_type = var.load_balancer_type
  security_groups    = var.security_groups
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  access_logs {
    bucket  = var.s3_bucket_name
    prefix  = "${var.lb_name}-lb"
    enabled = var.logs_enabled
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.lb_name}-lb"
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

