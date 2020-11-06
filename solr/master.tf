# USERDATA

data "template_file" "master_user_data" {
  template = file("../user_data/solr_user_data.sh")

  vars = {
    env_identifier             = local.environment_identifier
    short_env_identifier       = local.short_environment_identifier
    app_name                   = local.alfresco_app_name
    cldwatch_log_group         = module.create_loggroup.loggroup_name
    region                     = var.region
    cache_home                 = "/srv/cache"
    ebs_device                 = "/dev/xvdb"
    app_name                   = local.alfresco_app_name
    route53_sub_domain         = "${local.alfresco_app_name}.${local.environment}"
    private_domain             = local.internal_domain
    private_zone_id            = local.private_zone_id
    account_id                 = local.account_id
    internal_domain            = local.internal_domain
    elasticsearch_url          = local.elasticsearch_props["url"]
    elasticsearch_cluster_name = local.elasticsearch_props["cluster_name"]
    cluster_subnet             = ""
    cluster_name               = "${local.environment_identifier}-public-ecs-cluster"
    db_name                    = local.db_name
    db_host                    = local.db_host
    db_user                    = local.db_username_ssm
    db_password                = local.db_password_ssm
    s3_bucket_config           = local.config-bucket
    ssm_get_command            = "aws --region ${var.region} ssm get-parameters --names"
    messaging_broker_url       = local.messaging_broker_url
    messaging_broker_password  = local.messaging_broker_password
    #s3 config data
    bucket_name         = local.s3bucket
    bucket_encrypt_type = "kms"
    bucket_key_id       = local.s3bucket_kms_id
    external_fqdn       = "localhost"
    # For bootstrapping
    bastion_inventory    = var.bastion_inventory
    bootstrap_version    = var.source_code_versions["boostrap"]
    alfresco_version     = var.source_code_versions["alfresco"]
    logstash_version     = var.source_code_versions["logstash"]
    elasticbeats_version = var.source_code_versions["elasticbeats"]
    solr_version         = var.source_code_versions["solr"]
    # SOLR
    solr_port             = local.solr_port
    solr_device_name      = var.alf_solr_config["ebs_device_name"]
    solr_volume_name      = local.common_name
    solr_java_xms         = var.alf_solr_config["java_xms"]
    solr_java_xmx         = var.alf_solr_config["java_xmx"]
    jvm_memory            = var.alf_solr_config["alf_jvm_memory"]
    backups_bucket        = local.backups_bucket
    solr_temp_device_name = var.alf_solr_config["ebs_temp_device_name"]
    solr_temp_volume_name = "${local.common_name}-temp"
    solr_temp_dir         = "/tmp/solr"
  }
}
