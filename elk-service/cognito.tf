resource "aws_cognito_user_pool" "pool" {
  name = local.common_name
  tags = merge(
    local.tags,
    {
      "Name" = local.common_name
    },
  )
  auto_verified_attributes   = ["email"]
  alias_attributes           = ["email"]
  email_verification_subject = "HMPSS Monitoring Verification Code"
  password_policy {
    minimum_length                   = lookup(var.alf_cognito_map, "minimum_length", 12)
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = lookup(var.alf_cognito_map, "require_symbols", false)
    require_uppercase                = true
    temporary_password_validity_days = lookup(var.alf_cognito_map, "temporary_password_validity_days", 2)
  }
  admin_create_user_config {
    allow_admin_create_user_only = true
  }
  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = false
  }
}

# iam
data "template_file" "pool_assume" {
  template = file("./policies/assume.json")
  vars     = {}
}

data "template_file" "pool" {
  template = file("./policies/role.json")
  vars = {
    account_id = local.account_id
  }
}

resource "aws_iam_role" "pool" {
  name               = "${local.common_name}-role"
  assume_role_policy = data.template_file.pool_assume.rendered
  description        = "${local.common_name}-role"
}

resource "aws_iam_role_policy" "pool" {
  name   = "${local.common_name}-pol"
  role   = aws_iam_role.pool.name
  policy = data.template_file.pool.rendered
}

# domain 
resource "aws_cognito_user_pool_domain" "pool" {
  domain       = local.common_name
  user_pool_id = aws_cognito_user_pool.pool.id
}

# client
resource "aws_cognito_user_pool_client" "client" {
  name                                 = "${local.common_name}-kibana"
  user_pool_id                         = aws_cognito_user_pool.pool.id
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  supported_identity_providers         = ["COGNITO"]
  callback_urls = [
    "${local.kibana_host_url}/oauth2/idpresponse",
    "https://${module.kibana_alb.lb_dns_name}/oauth2/idpresponse",
  ]
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = [
    "email",
    "openid",
  ]
  read_attributes = [
    "email",
    "zoneinfo",
    "website",
    "preferred_username",
    "name",
    "locale",
    "phone_number",
    "family_name",
    "birthdate",
    "middle_name",
    "phone_number_verified",
    "picture",
    "address",
    "gender",
    "updated_at",
    "nickname",
    "profile",
    "given_name",
    "email_verified",
  ]
  write_attributes = [
    "email",
    "zoneinfo",
    "website",
    "preferred_username",
    "name",
    "locale",
    "family_name",
    "birthdate",
    "middle_name",
    "picture",
    "address",
    "gender",
    "updated_at",
    "nickname",
    "profile",
    "given_name",
  ]
}

