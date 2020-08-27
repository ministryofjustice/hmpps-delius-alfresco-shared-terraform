#-------------------------------------------------------------
### IAM Role
#-------------------------------------------------------------

data "template_file" "lambda" {
  template = file("../policies/log_exporter.json")

  vars = {
    logs_bucket_arn = local.logs_bucket_arn
    alf_group_arn   = aws_cloudwatch_log_group.lambda.arn
  }
}

resource "aws_iam_role" "lambda" {
  name               = local.function_name
  assume_role_policy = file("policies/lambda_policy.json")
  description        = local.function_name
}

module "lambda-policy" {
  source     = "../modules/iam/rolepolicy"
  policyfile = data.template_file.lambda.rendered
  rolename   = aws_iam_role.lambda.name
}

