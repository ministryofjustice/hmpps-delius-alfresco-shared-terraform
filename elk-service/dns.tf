resource "aws_service_discovery_private_dns_namespace" "elk" {
  name        = local.service_discovery_domain
  description = "Service Discovery Service - ${local.common_name}"
  vpc         = local.vpc_id
}

resource "aws_service_discovery_service" "kibana" {
  name = "kibana"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.elk.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

