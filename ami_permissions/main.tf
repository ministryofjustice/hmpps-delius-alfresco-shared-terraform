terraform {
  backend "s3" {
  }
}

locals {
  alfresco_asg_props = merge(var.alfresco_asg_props, var.alf_config_map)
  account_alias      = "hmpps-${var.environment_name}"
  image_id           = local.alfresco_asg_props["image_id"]
  account_id         = lookup(var.alf_account_ids, local.account_alias)
}

resource "null_resource" "ami_update_perms" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "sh scripts/update_ami.sh ${local.image_id} ${local.account_id} ${var.region}"
  }
}

resource "null_resource" "ami_perms" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "aws --region ${var.region} ec2 describe-image-attribute --image-id ${local.image_id} --attribute launchPermission"
  }
  depends_on = [null_resource.ami_update_perms]
}
