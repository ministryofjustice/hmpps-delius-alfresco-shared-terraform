#dashboard
resource "aws_cloudwatch_dashboard" "alf" {
  dashboard_name = local.common_name
  dashboard_body = data.template_file.dashboard.rendered
}

data "template_file" "dashboard" {
  template = file("./files/dashboard.json")
  vars = {
    region                  = var.region
    common_prefix           = data.terraform_remote_state.common.outputs.common_name
  }
}
