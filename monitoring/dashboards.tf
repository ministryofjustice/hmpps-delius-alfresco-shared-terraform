resource "aws_cloudwatch_dashboard" "alfresco_ecs" {
  dashboard_name = "alfresco_ecs"
  dashboard_body = data.template_file.alfresco_ecs.rendered
}

data "template_file" "alfresco_ecs" {
  template = "${file("${path.module}/templates/dashboards/alfresco_ecs.tpl")}"
  vars = {
    environment_name = "${var.environment_name}"
  }
}
