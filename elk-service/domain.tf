resource "aws_cloudwatch_log_group" "es" {
  name              = local.common_name
  retention_in_days = var.cloudwatch_log_retention
  kms_key_id        = local.logs_kms_arn
  tags = merge(
    local.tags,
    {
      "Name" = local.common_name
    },
  )
}

resource "aws_cloudwatch_log_resource_policy" "example" {
  policy_name     = "${local.common_name}-logs-pol"
  policy_document = data.aws_iam_policy_document.es_cloudwatch_policy.json
}

resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
  count            = lookup(local.alf_elk_service_props, "create_service_role", 0)
}

resource "aws_elasticsearch_domain" "es" {
  domain_name           = local.common_name
  elasticsearch_version = lookup(local.alf_elk_service_props, "elasticsearch_version", "6.8")

  cluster_config {
    instance_type            = lookup(local.alf_elk_service_props, "instance_type", "t2.medium.elasticsearch")
    dedicated_master_enabled = lookup(local.alf_elk_service_props, "dedicated_master_enabled", true)
    dedicated_master_count   = lookup(local.alf_elk_service_props, "dedicated_master_count", 3)
    dedicated_master_type    = lookup(local.alf_elk_service_props, "dedicated_master_type", "t2.medium.elasticsearch")
    zone_awareness_enabled   = lookup(local.alf_elk_service_props, "zone_awareness_enabled", true)
    instance_count           = lookup(local.alf_elk_service_props, "instance_count", 3)
    zone_awareness_config {
      availability_zone_count = lookup(local.alf_elk_service_props, "availability_zone_count", 3)
    }
  }

  ebs_options {
    ebs_enabled = lookup(local.alf_elk_service_props, "es_ebs_enabled", true)
    volume_type = lookup(local.alf_elk_service_props, "es_ebs_type", "gp2")
    volume_size = lookup(local.alf_elk_service_props, "es_ebs_size", 10)
    iops        = lookup(local.alf_elk_service_props, "iops", 0)
  }

  vpc_options {
    subnet_ids         = flatten(local.private_subnet_ids)
    security_group_ids = [aws_security_group.es.id]
  }

  access_policies = templatefile(
    "${path.module}/templates/iam/es_access_policy.conf",
    {
      domain_name = local.common_name
      region      = var.region
      account_id  = local.account_id
    }
  )

  snapshot_options {
    automated_snapshot_start_hour = lookup(local.alf_elk_service_props, "automated_snapshot_start_hour", 23)
  }

  encrypt_at_rest {
    enabled = lookup(local.alf_elk_service_props, "encrypt_at_rest", true)
  }

  node_to_node_encryption {
    enabled = lookup(local.alf_elk_service_props, "node_to_node_encryption", true)
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = lookup(local.alf_elk_service_props, "tls_security_policy", "Policy-Min-TLS-1-2-2019-07")
  }

  log_publishing_options {
    enabled                  = true
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.es.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  log_publishing_options {
    enabled                  = true
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.es.arn
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  log_publishing_options {
    enabled                  = true
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.es.arn
    log_type                 = "ES_APPLICATION_LOGS"
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.common_name}"
    },
  )

}
