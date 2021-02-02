# ASG Configuration
alf_config_map = {
  asg_ami  = "ami-01a89d36a33a6c7fc"
  ami_name = "HMPPS Alfresco *"
  image_id = "ami-01a89d36a33a6c7fc"
}

solr_config_map = {
  ami_id = "ami-039e4527aad6b181a"
  ami_name = "HMPPS Solr *"
  image_id = "ami-039e4527aad6b181a"
}

source_code_versions = {
  boostrap         = "centos"
  alfresco         = "patch/pre-solr-ha" # Will be used until Solr HA in place
  alfresco_tracker = "0.0.10"
  logstash         = "1.0.1"
  elasticbeats     = "1.0.1"
  solr             = "0.0.6"
  solr_ha          = "0.0.1"
  esadmin          = "0.0.6"
}
