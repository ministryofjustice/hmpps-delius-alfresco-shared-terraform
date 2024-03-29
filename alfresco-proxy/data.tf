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
### Getting the ecs cluster details
#-------------------------------------------------------------
data "terraform_remote_state" "ecs_cluster" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/ecs_cluster/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the load balancer details
#-------------------------------------------------------------
data "terraform_remote_state" "load_balancer" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/app-internal-load-balancer/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "external_load_balancer" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/app-external-load-balancer/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the s3 details
#-------------------------------------------------------------
data "terraform_remote_state" "s3bucket" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/s3buckets/terraform.tfstate"
    region = var.region
  }
}

data "aws_s3_bucket" "config_bucket" {
  bucket = local.config_bucket_name
}

#-------------------------------------------------------------
### Getting the rds details
#-------------------------------------------------------------
data "terraform_remote_state" "rds" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/database/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
## Getting the rds db password
#-------------------------------------------------------------
data "aws_ssm_parameter" "db_user" {
  name = data.terraform_remote_state.rds.outputs.rds_creds["db_username_ssm_param"]
}

data "aws_ssm_parameter" "db_password" {
  name = data.terraform_remote_state.rds.outputs.rds_creds["db_password_ssm_param"]
}

#-------------------------------------------------------------
### Getting the firehose details
#-------------------------------------------------------------
data "terraform_remote_state" "firehose" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/firehose-stream/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the share details
#-------------------------------------------------------------
data "terraform_remote_state" "share" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/alfresco-share/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting the content details
#-------------------------------------------------------------
data "terraform_remote_state" "content" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/alfresco-content/terraform.tfstate"
    region = var.region
  }
}

#-------------------------------------------------------------
### Getting ACM Cert
#-------------------------------------------------------------
data "aws_acm_certificate" "cert" {
  domain      = "*.${data.terraform_remote_state.common.outputs.external_domain}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

#-------------------------------------------------------------
### Getting VPC CIDR - required because we want to derive the Amazon DNS Server IP for the VPC
#-------------------------------------------------------------
data "aws_vpc" "vpc" {
  id = local.vpc_id
}

# Nginx template
data "template_file" "nginx_host" {
  template = file("${path.module}/templates/config/host.conf")

  vars = {
    alfresco_endpoint = data.terraform_remote_state.content.outputs.info["end_point"]
    share_endpoint    = data.terraform_remote_state.share.outputs.info["end_point"]
    vpc_dns_ip        = cidrhost(data.aws_vpc.vpc.cidr_block, 2) # Derive IP of Amazon DNS endpoint in VPC
  }
}
