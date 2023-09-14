####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################
#-------------------------------------------------------------
### Getting the common details
#-------------------------------------------------------------
data "terraform_remote_state" "common" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/common/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the s3 details
#-------------------------------------------------------------
data "terraform_remote_state" "s3bucket" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/s3buckets/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the elk details
#-------------------------------------------------------------

# IAM Templates
data "aws_iam_policy_document" "firehose-role-assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

# policy
data "aws_iam_policy_document" "firehose_policy" {
  # Commented out pending testing
  # statement {
  #   sid    = "PushLogsToES"
  #   effect = "Allow"
  #   actions = [
  #     "es:*"
  #   ]
  #   resources = [
  #     local.es_cluster_arn,
  #     format("%s/*", local.es_cluster_arn)
  #   ]
  # }
  statement {
    sid    = "AccessS3Bucket"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      module.bucket.s3_bucket_arn,
      format("%s/*", module.bucket.s3_bucket_arn)
    ]
  }
  statement {
    sid    = "EC2Perms"
    effect = "Allow"
    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:DeleteNetworkInterface"
    ]
    resources = ["*"]
  }
}
