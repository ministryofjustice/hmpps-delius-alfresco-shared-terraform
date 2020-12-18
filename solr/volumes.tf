locals {
  ebs_iops = local.solr_asg_props["ebs_iops"]
  ebs_type = local.solr_asg_props["ebs_type"]
}

module "solr_volume_az1" {
  source            = "./modules/volumes"
  availability_zone = element(flatten(local.private_subnet_ids), 0)
  ebs_data_type     = local.solr_asg_props["ebs_type"]
  ebs_data_size     = local.solr_asg_props["ebs_size"]
  ebs_data_iops     = local.ebs_type == "gp2" ? 0 : local.ebs_iops
  ebs_temp_type     = local.solr_asg_props["ebs_temp_type"]
  ebs_temp_size     = local.solr_asg_props["ebs_temp_size"]
  ebs_temp_iops     = 0
  prefix            = "${local.common_name}"
  tags              = local.tags
}

module "solr_volume_az2" {
  source            = "./modules/volumes"
  availability_zone = element(flatten(local.private_subnet_ids), 1)
  ebs_data_type     = local.solr_asg_props["ebs_type"]
  ebs_data_size     = local.solr_asg_props["ebs_size"]
  ebs_data_iops     = local.ebs_type == "gp2" ? 0 : local.ebs_iops
  ebs_temp_type     = local.solr_asg_props["ebs_temp_type"]
  ebs_temp_size     = local.solr_asg_props["ebs_temp_size"]
  ebs_temp_iops     = 0
  prefix            = "${local.common_name}"
  tags              = local.tags
}

module "solr_volume_az3" {
  source            = "./modules/volumes"
  availability_zone = element(flatten(local.private_subnet_ids), 2)
  ebs_data_type     = local.solr_asg_props["ebs_type"]
  ebs_data_size     = local.solr_asg_props["ebs_size"]
  ebs_data_iops     = local.ebs_type == "gp2" ? 0 : local.ebs_iops
  ebs_temp_type     = local.solr_asg_props["ebs_temp_type"]
  ebs_temp_size     = local.solr_asg_props["ebs_temp_size"]
  ebs_temp_iops     = 0
  prefix            = "${local.common_name}"
  tags              = local.tags
}
