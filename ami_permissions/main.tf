terraform {
  backend "s3" {
  }
}

locals {
  account_alias = "hmpps-${var.environment_name}"
  alf_image_id  = var.alf_config_map["image_id"]
  solr_image_id = var.solr_config_map["image_id"]
  account_id    = lookup(var.alf_account_ids, local.account_alias)
}

module "alfresco" {
  source     = "./modules/ami"
  account_id = local.account_id
  image_id   = local.alf_image_id
  region     = var.region
}

module "solr" {
  source     = "./modules/ami"
  account_id = local.account_id
  image_id   = local.solr_image_id
  region     = var.region
}
