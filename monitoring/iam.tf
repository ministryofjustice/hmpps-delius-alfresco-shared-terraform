#-------------------------------------------------------------
### IAM Role
#-------------------------------------------------------------

data "template_file" "lambda" {
  template = "${file("../policies/lamba_ops_alerts.json")}"

  vars {
    ssm_token_arn = "${data.aws_ssm_parameter.ssm_token.arn}"
    config-bucket = "${local.config-bucket}"
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.function_name}"
  assume_role_policy = "${file("policies/assume.json")}"
  description        = "${local.function_name}"
}

module "lambda-policy" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//iam//rolepolicy"
  policyfile = "${data.template_file.lambda.rendered}"
  rolename   = "${aws_iam_role.lambda.name}"
}
