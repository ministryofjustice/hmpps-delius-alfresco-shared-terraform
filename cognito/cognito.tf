resource "aws_cognito_user_pool" "pool" {
  name                       = "${local.common_name}"
  tags                       = "${merge(local.tags, map("Name", "${local.common_name}"))}"
  auto_verified_attributes   = ["email"]
  alias_attributes           = ["email"]
  email_verification_subject = "HMPSS Monitoring Verification Code"
  # mfa_configuration          = "ON"
  password_policy {
    minimum_length    = "${var.alf_cognito_map["minimum_length"]}"
    require_lowercase = true
    require_numbers   = true
    require_symbols   = "${var.alf_cognito_map["require_symbols"]}"
    require_uppercase = true
  }
  admin_create_user_config {
    allow_admin_create_user_only = true
    unused_account_validity_days = "${var.alf_cognito_map["unused_account_validity_days"]}"

  }
  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = false
  }
  # sms_configuration {
  #   external_id    = "${local.common_name}_sns_external_id"
  #   sns_caller_arn = "${aws_iam_role.pool.arn}"
  # }
}

# iam
data "template_file" "pool_assume" {
  template = "${file("./policies/assume.json")}"
  vars {}
}
data "template_file" "pool" {
  template = "${file("./policies/role.json")}"
  vars {
    account_id = "${local.account_id}"
  }
}

resource "aws_iam_role" "pool" {
  name               = "${local.common_name}-role"
  assume_role_policy = "${data.template_file.pool_assume.rendered}"
  description        = "${local.common_name}-role"
}

resource "aws_iam_role_policy" "pool" {
  name   = "${local.common_name}-pol"
  role   = "${aws_iam_role.pool.name}"
  policy = "${data.template_file.pool.rendered}"
}

# domain 
resource "aws_cognito_user_pool_domain" "pool" {
  domain       = "${local.app_name}"
  user_pool_id = "${aws_cognito_user_pool.pool.id}"
}


# client
resource "aws_cognito_user_pool_client" "client" {
  name                                 = "${local.common_name}-client"
  user_pool_id                         = "${aws_cognito_user_pool.pool.id}"
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  supported_identity_providers         = ["COGNITO"]
  callback_urls = [
    "https://alf5kibana.dev.alfresco.probation.hmpps.dsd.io/oauth2/idpresponse",
    "https://tf-alf-dev-mig-kib-lb-1050160259.eu-west-2.elb.amazonaws.com/oauth2/idpresponse"
  ]
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = [
    "email",
    "openid"
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
    "email_verified"
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
    "given_name"
  ]
}
