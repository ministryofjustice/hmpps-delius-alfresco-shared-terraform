#-------------------------------------------------------------
### Getting the latest amazon ami
#-------------------------------------------------------------
data "aws_ami" "db_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["HMPPS Base CentOS master *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["${data.terraform_remote_state.common.common_account_id}", "895523100917"] # AWS
}

#-------------------------------------------------------------
### Getting the rds db password
#-------------------------------------------------------------
data "aws_ssm_parameter" "db_password_ssm" {
  name = "${local.common_name}-rds-db-password"
}

locals {
  device_list   = ["/dev/xvdb"]
  db_subnet_ids = ["${data.terraform_remote_state.common.db_subnet_ids}"]

  db_security_groups = [
    "sg-0cf7b889af05c6714",
    "${data.terraform_remote_state.common.common_sg_outbound_id}",
    "${data.terraform_remote_state.common.monitoring_server_client_sg_id}",
  ]
}

####
data "template_file" "db_userdata" {
  template = "${file("../user_data/db_user_data.sh")}"

  vars {
    app_name             = "${local.alfresco_app_name }"
    env_identifier       = "${local.environment_identifier}"
    short_env_identifier = "${local.short_environment_identifier}"
    route53_sub_domain   = "${local.environment}.${local.alfresco_app_name }"
    private_domain       = "${local.internal_domain}"
    account_id           = "${local.account_id}"
    internal_domain      = "${local.internal_domain}"
    environment          = "${local.environment}"
    ebs_device           = "/dev/xvdb"
    POSTGRES_USER        = "${local.db_username}"
    POSTGRES_DB          = "${local.db_name}"
    POSTGRES_PASSWORD    = "${data.aws_ssm_parameter.db_password_ssm.value}"
    bastion_inventory    = "${local.bastion_inventory}"
  }
}

#-------------------------------------------------------------
### Create db 
#-------------------------------------------------------------
module "db" {
  source                      = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//ec2"
  app_name                    = "${local.environment_identifier}-db-ec2"
  ami_id                      = "${data.aws_ami.db_ami.id}"
  instance_type               = "${var.asg_instance_type}"
  subnet_id                   = "${local.db_subnet_ids[0]}"                                                                      #"${local.private_subnet_map["az1"]}"
  iam_instance_profile        = "${local.instance_profile}"
  associate_public_ip_address = false
  monitoring                  = true
  user_data                   = "${data.template_file.db_userdata.rendered}"
  CreateSnapshot              = false
  tags                        = "${local.tags}"
  key_name                    = "${local.ssh_deployer_key}"
  root_device_size            = "30"

  vpc_security_group_ids = [
    "${local.db_security_groups}",
  ]
}

#-------------------------------------------------------------
### EBS Volumes
#-------------------------------------------------------------

resource "aws_ebs_volume" "data_disk" {
  count             = "1"
  availability_zone = "eu-west-2a"
  size              = 100
  encrypted         = true

  tags = "${merge(
    local.tags,
    map("Name", "${local.environment_identifier}-${local.alfresco_app_name }"),
    map("CreateSnapshot", true)
  )}"
}

resource "aws_volume_attachment" "data_volume_attachment" {
  count        = "1"
  device_name  = "${element(local.device_list, count.index )}"
  instance_id  = "${module.db.instance_id}"
  volume_id    = "${element(aws_ebs_volume.data_disk.*.id, count.index)}"
  skip_destroy = "true"
}
