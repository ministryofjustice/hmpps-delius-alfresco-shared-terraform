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
### Getting the security-groups details
#-------------------------------------------------------------
data "terraform_remote_state" "security_groups" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket_name
    key    = "alfresco/security-groups/terraform.tfstate"
    region = var.region
  }
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
