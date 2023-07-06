resource "aws_cloudwatch_dashboard" "alfresco_ecs" {
  dashboard_name = "alfresco_ecs"
  dashboard_body = data.template_file.alfresco_ecs.rendered
}
