terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

provider "aws" {
  region  = "${var.region}"
  version = "~> 1.16"
}

####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

#-------------------------------------------------------------
### Getting the current vpc
#-------------------------------------------------------------
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "vpc/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the common details
#-------------------------------------------------------------
data "terraform_remote_state" "common" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "${var.alfresco_app_name}/common/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the engineering ecr repos
#-------------------------------------------------------------
data "terraform_remote_state" "ecr" {
  backend = "s3"

  config {
    bucket   = "${var.eng-remote_state_bucket_name}"
    key      = "ecr/terraform.tfstate"
    region   = "${var.region}"
    role_arn = "${var.eng_role_arn}"
  }
}

#-------------------------------------------------------------
### Getting the engineer vpc
#-------------------------------------------------------------
data "terraform_remote_state" "remote_vpc" {
  backend = "s3"

  config {
    bucket   = "${var.eng-remote_state_bucket_name}"
    key      = "vpc/terraform.tfstate"
    region   = "${var.region}"
    role_arn = "${var.eng_role_arn}"
  }
}

#-------------------------------------------------------------
### Getting the alfresco IAM role
#-------------------------------------------------------------
data "terraform_remote_state" "remote_iam" {
  backend = "s3"

  config {
    bucket   = "${var.eng-remote_state_bucket_name}"
    key      = "alfresco/iam/terraform.tfstate"
    region   = "${var.region}"
    role_arn = "${var.eng_role_arn}"
  }
}

#-------------------------------------------------------------
### Getting the s3 bucket
#-------------------------------------------------------------

data "terraform_remote_state" "s3-buckets" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "${var.alfresco_app_name}/service-alfresco/s3bucket/terraform.tfstate"
    region = "${var.region}"
  }
}

####################################################
# Locals
####################################################
locals {
  common_name = "${var.environment_identifier}-${var.alfresco_app_name}"
  tags        = "${data.terraform_remote_state.common.common_tags}"
}

############################################
# CREATE IAM POLICIES
############################################

#-------------------------------------------------------------
### INTERNAL IAM POLICES FOR EC2 RUNNING ECS SERVICES
#-------------------------------------------------------------

data "template_file" "iam_policy_app_int" {
  template = "${file("policies/ec2_internal_policy.json")}"

  vars {
    s3-config-bucket     = "${data.terraform_remote_state.common.common_s3-config-bucket}"
    app_role_arn         = "${module.create-iam-app-role-int.iamrole_arn}"
    aws_ecr_arn          = "${data.terraform_remote_state.ecr.ecr_repo_repository_arn_alfresco}"
    remote_iam_role      = "${data.terraform_remote_state.remote_iam.alfresco_iam_arn}"
    remote_config_bucket = "${data.terraform_remote_state.remote_vpc.s3-config-bucket}"
    storage_s3bucket     = "${data.terraform_remote_state.s3-buckets.service_alfresco_s3bucket}"
  }
}

module "create-iam-app-role-int" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//iam//role"
  rolename   = "${local.common_name}-int-ec2"
  policyfile = "${var.ec2_policy_file}"
}

module "create-iam-instance-profile-int" {
  source = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//iam//instance_profile"
  role   = "${module.create-iam-app-role-int.iamrole_name}"
}

module "create-iam-app-policy-int" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//iam//rolepolicy"
  policyfile = "${data.template_file.iam_policy_app_int.rendered}"
  rolename   = "${module.create-iam-app-role-int.iamrole_name}"
}
