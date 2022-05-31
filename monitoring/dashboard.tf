#dashboard

data "aws_lb_target_group" "target_group" {
  name = "${var.short_environment_identifier}-alf-app"
}

data "aws_lb" "alb" {
  name = "${var.short_environment_identifier}-alf-ext"
}

resource "aws_cloudwatch_dashboard" "alf" {
  dashboard_name = local.common_name
  dashboard_body = data.template_file.dashboard.rendered
}

data "template_file" "dashboard" {
  template = file("./files/dashboard.json")
  vars = {
    region                  = var.region
    asg_autoscale_name      = data.terraform_remote_state.asg.outputs.asg_autoscale_name
    common_prefix           = data.terraform_remote_state.common.outputs.common_name
    lb_arn_suffix           = data.aws_lb.alb.arn_suffix
    target_group_arn_suffix = data.aws_lb_target_group.target_group.arn_suffix
  }
}
