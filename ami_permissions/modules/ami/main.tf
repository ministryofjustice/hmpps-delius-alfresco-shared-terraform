resource "null_resource" "ami_update_perms" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "sh ${path.module}/scripts/update_ami.sh ${var.image_id} ${var.account_id} ${var.region}"
  }
}

resource "null_resource" "ami_perms" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "aws --region ${var.region} ec2 describe-image-attribute --image-id ${var.image_id} --attribute launchPermission"
  }
  depends_on = [null_resource.ami_update_perms]
}

