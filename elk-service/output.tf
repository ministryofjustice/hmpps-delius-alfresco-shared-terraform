output "elk_service" {
  value = {
    es_sg_id        = aws_security_group.es.id
    endpoint        = aws_elasticsearch_domain.es.endpoint
    domain_name     = aws_elasticsearch_domain.es.domain_name
    arn             = aws_elasticsearch_domain.es.arn
    kibana_endpoint = local.kibana_host_url
    kibana_asg_name = aws_autoscaling_group.kibana.name
    access_sg       = aws_security_group.access_es.id
    es_url          = local.es_url
    snapshot_role   = aws_iam_role.elasticsearch.name
    lambda_role     = module.es-lambda.iamrole_name
  }
}
