module "solr_volume_az1" {
  source            = "../modules/ebs/volumes"
  availability_zone = element(flatten(local.subnet_ids), 0)
  ebs_data_type     = local.alfresco_search_solr_props["ebs_type"]
  ebs_data_size     = local.alfresco_search_solr_props["ebs_size"]
  ebs_data_iops     = local.ebs_type == "gp2" ? 0 : local.ebs_iops
  prefix            = local.data_volume_name
  tags              = local.tags
  kms_key_id        = local.storage_kms_arn
}

module "solr_volume_az2" {
  source            = "../modules/ebs/volumes"
  availability_zone = element(flatten(local.subnet_ids), 1)
  ebs_data_type     = local.alfresco_search_solr_props["ebs_type"]
  ebs_data_size     = local.alfresco_search_solr_props["ebs_size"]
  ebs_data_iops     = local.ebs_type == "gp2" ? 0 : local.ebs_iops
  prefix            = local.data_volume_name
  tags              = local.tags
  kms_key_id        = local.storage_kms_arn
  create            = 1
}

module "solr_volume_az3" {
  source            = "../modules/ebs/volumes"
  availability_zone = element(flatten(local.subnet_ids), 2)
  ebs_data_type     = local.alfresco_search_solr_props["ebs_type"]
  ebs_data_size     = local.alfresco_search_solr_props["ebs_size"]
  ebs_data_iops     = local.ebs_type == "gp2" ? 0 : local.ebs_iops
  prefix            = local.data_volume_name
  tags              = local.tags
  kms_key_id        = local.storage_kms_arn
  create            = 1
}
