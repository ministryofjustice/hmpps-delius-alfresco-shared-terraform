resource "aws_s3_bucket" "bucket" {
  bucket = local.common_name
  acl    = "private"

  versioning {
    enabled = false
  }

  lifecycle {
    prevent_destroy = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.common_name}"
    },
  )
}

module "iam_role" {
  source     = "../modules/iam/role"
  rolename   = local.common_name
  policyfile = "ec2_policy.json"
}

module "iam_profile" {
  source = "../modules/hmpps-terraform-modules/iam/instance_profile"
  role   = module.iam_role.iamrole_name
}

data "template_file" "policy" {
  template = file("./policies/ec2.json")

  vars = {
    bucket = aws_s3_bucket.bucket.id
  }
}

module "role_policy" {
  source     = "../modules/hmpps-terraform-modules/iam/rolepolicy"
  policyfile = data.template_file.policy.rendered
  rolename   = module.iam_role.iamrole_name
}

data "template_file" "userdata" {
  template = file("./userdata/userdata.sh")
  vars     = {}
}

resource "aws_instance" "instance" {
  ami                         = local.ami_id
  instance_type               = "t2.medium"
  subnet_id                   = element(flatten(local.public_subnet_ids), 0)
  iam_instance_profile        = module.iam_profile.iam_instance_name
  associate_public_ip_address = true
  vpc_security_group_ids      = flatten([aws_security_group.environment.id])
  key_name                    = module.ssh_key.deployer_key
  monitoring                  = true
  user_data                   = data.template_file.userdata.rendered

  tags = merge(
    local.tags,
    {
      "Name" = local.common_name
    }
  )

  root_block_device {
    volume_size = "20"
  }
  lifecycle {
    ignore_changes = [ami]
  }
}
ec2 
