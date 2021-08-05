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
### Getting the security groups details
#-------------------------------------------------------------
data "terraform_remote_state" "security-groups" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/security-groups/terraform.tfstate"
    region = var.region
  }
}

# Search for ami id
data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  # Amazon Linux 2 optimised ECS instance
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*"]
  }

  # correct arch
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  # Owned by Amazon
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Templates
data "aws_iam_policy_document" "ecs_assume_role_template" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
        type        = "Service"
        identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "template_file" "ecs_host_role_policy_template" {
  template = file("${path.module}/templates/iam/ecs-host-role-policy.tpl")
  vars     = {}
}

# Host userdata template
data "template_file" "ecs_host_userdata_template" {
  template = file("${path.module}/templates/ec2/ecs-host-userdata.tpl")

  vars = {
    ecs_cluster_name         = local.ecs_cluster_name
    region                   = var.region
    efs_sg                   = local.ecs_security_groups["efs"]
    log_group_name           = module.create_loggroup.loggroup_name
  }
}
