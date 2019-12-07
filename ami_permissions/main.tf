terraform {
  backend "s3" {}
}

provider "aws" {
  region  = "${var.region}"
  version = "~> 1.16"
}

locals {
  account_id = "hmpps-${var.environment_name}"
  image_id   = "${var.alfresco_asg_props["image_id"]}"
}

# resource "aws_ami_launch_permission" "ami" {
#   image_id   = "${var.alfresco_asg_props["image_id"]}"
#   account_id = "${var.alf_account_ids["${local.account_id}"]}"
# }

resource "null_resource" "ami_update_perms" {
  triggers = {
    ami_sha = "${sha1(data.template_file.ami.rendered)}"
  }
  provisioner "local-exec" {
    command = "sh scripts/update_ami.sh ${local.image_id} ${var.alf_account_ids["${local.account_id}"]}"
  }
}

resource "null_resource" "ami_perms" {
  triggers = {
    ami_sha = "${sha1(data.template_file.ami.rendered)}"
  }
  provisioner "local-exec" {
    command = "aws ec2 describe-image-attribute --image-id ${local.image_id} --attribute launchPermission"
  }
  depends_on = ["null_resource.ami_update_perms"]
}
