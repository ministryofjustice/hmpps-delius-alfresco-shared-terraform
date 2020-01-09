resource "aws_wafregional_byte_match_set" "wafrule" {
  name = "AlfNomsSearchInURI"
  byte_match_tuples {
    text_transformation   = "NONE"
    target_string         = "/alfresco/service/noms-spg/search"
    positional_constraint = "STARTS_WITH"
    field_to_match {
      type = "URI"
    }
  }
}

resource "aws_wafregional_rate_based_rule" "wafrule" {
  depends_on  = ["aws_wafregional_byte_match_set.wafrule"]
  name        = "AlfNomsSearchWafRateRule"
  metric_name = "AlfNomsSearchWafRateRule"

  rate_key   = "IP"
  rate_limit = 2000

  predicate {
    data_id = "${aws_wafregional_byte_match_set.wafrule.id}"
    negated = false
    type    = "ByteMatch"
  }
}

resource "aws_wafregional_rule" "wafrule" {
  name        = "AlfNomsSearchWAFRule"
  metric_name = "AlfNomsSearchWAFRule"

  predicate {
    type    = "ByteMatch"
    data_id = "${aws_wafregional_byte_match_set.wafrule.id}"
    negated = false
  }
}


resource "aws_wafregional_web_acl" "wafacl" {
  name        = "${local.web_acl_name}"
  metric_name = "${local.web_acl_name}"

  default_action {
    type = "ALLOW"
  }

  rule {
    action {
      type = "BLOCK"
    }

    priority = 1
    rule_id  = "${aws_wafregional_rate_based_rule.wafrule.id}"
    type     = "RATE_BASED"
  }

  logging_configuration {
    log_destination = "${aws_kinesis_firehose_delivery_stream.firehose_stream.arn}"
  }
}

resource "aws_wafregional_web_acl_association" "wafacl" {
  resource_arn = "${local.load_balancer_id}"
  web_acl_id   = "${aws_wafregional_web_acl.wafacl.id}"
}
