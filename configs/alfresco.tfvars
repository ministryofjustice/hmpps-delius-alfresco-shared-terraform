# ASG Configuration
alf_config_map = {
  asg_ami  = "ami-0be9e24d7d3de80d9"
  ami_name = "HMPPS Alfresco *"
  image_id = "ami-0be9e24d7d3de80d9"
  vpn_ip   = "81.134.202.29/32" #MOJ_VPN
}

solr_config_map = {
  ami_id = "ami-039e4527aad6b181a"
  ami_name = "HMPPS Solr *"
  image_id = "ami-039e4527aad6b181a"
}

source_code_versions = {
  boostrap         = "centos"
  alfresco         = "0.0.16" # Will be used until Solr HA in place
  alfresco_tracker = "0.0.16"
  logstash         = "1.0.1"
  elasticbeats     = "1.0.1"
  solr             = "0.0.6"
  solr_ha          = "0.0.1"
  esadmin          = "0.0.6"
}
