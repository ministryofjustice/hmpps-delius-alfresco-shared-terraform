############################################
# DEPLOYER KEY FOR PROVISIONING
############################################

module "ssh_key" {
  source   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git//modules//ssh_key"
  keyname  = local.common_name
  rsa_bits = "4096"
}

# Add to SSM
module "create_parameter_ssh_key_private" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git//modules//ssm//parameter_store_file"
  parameter_name = "${local.common_name}-ssh-private-key"
  description    = "${local.common_name}-ssh-private-key"
  type           = "SecureString"
  value          = module.ssh_key.private_key_pem
  tags           = local.tags
}

module "create_parameter_ssh_key" {
  source         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git//modules//ssm//parameter_store_file"
  parameter_name = "${local.common_name}-ssh-public-key"
  description    = "${local.common_name}-ssh-public-key"
  type           = "String"
  value          = module.ssh_key.public_key_openssh
  tags           = local.tags
}

resource "aws_key_pair" "deployer" {
  key_name   = "${local.common_name}-deployer-key"
  public_key = module.ssh_key.public_key_openssh
}

