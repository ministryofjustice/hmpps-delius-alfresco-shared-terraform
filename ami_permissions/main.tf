terraform {
  backend "s3" {}
}

provider "aws" {
  region  = "${var.region}"
  version = "~> 1.16"
}

locals {
  account_id = "hmpps-${var.environment_name}"
}

resource "aws_ami_launch_permission" "ami" {
  image_id   = "${var.alfresco_asg_props["image_id"]}"
  account_id = "${var.alf_account_ids["${local.account_id}"]}"
}
