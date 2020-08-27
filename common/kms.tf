############################################
# KMS KEY GENERATION - LOGS ENCRYPTION
############################################
locals {
  kms_key_name = "${local.common_name}-logs"
}

resource "aws_kms_key" "kms" {
  description             = local.kms_key_name
  deletion_window_in_days = 14
  is_enabled              = true
  enable_key_rotation     = true
  policy                  = data.template_file.kms.rendered
  tags = merge(
    local.tags,
    {
      "Name" = local.kms_key_name
    },
  )
}

resource "aws_kms_alias" "kms" {
  name          = "alias/${local.kms_key_name}"
  target_key_id = aws_kms_key.kms.key_id
}

data "template_file" "kms" {
  template = file("policies/cloudwatch.kms.json")

  vars = {
    region     = local.region
    account_id = local.account_id
  }
}

