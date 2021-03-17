terraform {
  backend "s3" {
  }
}

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
### Getting the latest amazon ami
#-------------------------------------------------------------
data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["HMPPS Base Docker Centos*"]
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

  owners = [data.terraform_remote_state.common.outputs.common_account_id, "895523100917"] # MOJ
}

####################################################
# Locals
####################################################

locals {
  ami_id             = data.aws_ami.ami.id
  region             = var.region
  account_id         = data.terraform_remote_state.common.outputs.common_account_id
  common_name        = "tf-interview"
  tags               = data.terraform_remote_state.common.outputs.common_tags
  vpc_id             = data.terraform_remote_state.common.outputs.vpc_id
  internal_domain    = data.terraform_remote_state.common.outputs.internal_domain
  private_zone_id    = data.terraform_remote_state.common.outputs.private_zone_id
  public_subnet_ids  = [data.terraform_remote_state.common.outputs.public_subnet_ids]
  private_subnet_ids = [data.terraform_remote_state.common.outputs.private_subnet_ids]
}

