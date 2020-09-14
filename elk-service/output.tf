output "elk_service" {
  value = {
    es_sg_id        = aws_security_group.es.id
    endpoint        = aws_elasticsearch_domain.es.endpoint
    domain_name     = aws_elasticsearch_domain.es.domain_name
    arn             = aws_elasticsearch_domain.es.arn
    kibana_endpoint = local.kibana_host_url
    access_sg       = aws_security_group.access_es.id
    es_url          = local.es_url
  }
}
