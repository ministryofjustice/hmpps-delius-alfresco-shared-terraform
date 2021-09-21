resource "aws_iam_role" "firehose_role" {
  name               = format("%s-role", local.common_name)
  assume_role_policy = data.aws_iam_policy_document.firehose-role-assume.json
  description        = format("%s-role", local.common_name)
}

resource "aws_iam_role_policy" "firehose_policy" {
  name   = format("%s-policy", local.common_name)
  role   = aws_iam_role.firehose_role.id
  policy = data.aws_iam_policy_document.firehose_policy.json
}
