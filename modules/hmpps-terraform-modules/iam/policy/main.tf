resource "aws_iam_policy" "environment" {
  name        = "tf-${var.region}-terraform-${var.business_unit}-${var.project}-${var.environment}-${var.policyname}"
  description = var.policy_description
  policy      = file(var.policyfile)
}

