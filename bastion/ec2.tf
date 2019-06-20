####################################################
# instance 1
####################################################

data "template_file" "instance_userdata" {
  template = "${file("./user_data/userdata.sh")}"

  vars {
    app_name             = "${local.application}"
    bastion_inventory    = "${local.bastion_inventory}"
    env_identifier       = "${local.environment_identifier}"
    short_env_identifier = "${local.short_environment_identifier}"
    environment_name     = "${var.environment_name}"
    private_domain       = "${local.internal_domain}"
    account_id           = "${local.account_id}"
    internal_domain      = "${local.internal_domain}"
    environment          = "${local.environment}"
    common_name          = "${local.common_name}"
  }
}

#-------------------------------------------------------------
### Create instance 
#-------------------------------------------------------------
module "create-ec2-instance" {
  source                      = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//ec2"
  app_name                    = "${local.common_name}-${local.application}"
  ami_id                      = "${local.ami_id}"
  instance_type               = "${var.es_admin_instance_type}"
  subnet_id                   = "${local.public_subnet_ids[0]}"
  iam_instance_profile        = "${module.create-iam-instance-profile-es.iam_instance_name}"
  associate_public_ip_address = true
  monitoring                  = true
  user_data                   = "${data.template_file.instance_userdata.rendered}"
  CreateSnapshot              = false
  tags                        = "${local.tags}"
  key_name                    = "${local.ssh_deployer_key}"
  root_device_size            = "60"

  vpc_security_group_ids = [
    "${local.instance_security_groups}",
  ]
}

#-------------------------------------------------------------
# Create route53 entry for instance 1
#-------------------------------------------------------------

resource "aws_route53_record" "instance" {
  zone_id = "${local.public_zone_id}"
  name    = "${local.application}.${local.external_domain}"
  type    = "A"
  ttl     = "300"
  records = ["${module.create-ec2-instance.public_ip}"]
}

# ec2

output "bastion_host" {
  value = "${aws_route53_record.instance.fqdn}"
}
