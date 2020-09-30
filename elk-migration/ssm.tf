resource "aws_ssm_parameter" "elasticsearch_5" {
  name  = "/alfresco/elasticsearch/es5_endpoint"
  type  = "String"
  value = local.es_host_fqdn
}
