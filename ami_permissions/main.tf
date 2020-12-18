terraform {
  backend "s3" {
  }
}

locals {
  alfresco_asg_props = merge(var.alfresco_asg_props, var.alf_config_map)
  solr_asg_props     = merge(var.solr_asg_props, var.solr_config_map)
  account_alias      = "hmpps-${var.environment_name}"
  image_id           = local.alfresco_asg_props["image_id"]
  account_id         = lookup(var.alf_account_ids, local.account_alias)
}

module "alfresco" {
  source     = "./modules/ami"
  image_id   = local.alfresco_asg_props["image_id"]
  account_id = "hmpps-${var.environment_name}"
  region     = var.region
}


module "solr" {
  source     = "./modules/ami"
  image_id   = local.solr_asg_props["image_id"]
  account_id = "hmpps-${var.environment_name}"
  region     = var.region
}
