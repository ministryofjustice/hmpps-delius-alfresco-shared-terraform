# ASG Configuration
alf_config_map = {
  asg_ami  = "ami-072548d2dd6688dde"
  ami_name = "HMPPS Alfresco *"
  image_id = "ami-072548d2dd6688dde"
}

solr_config_map = {
  ami_id = "ami-02ce4079e4808de08"
}

source_code_versions = {
  boostrap     = "centos"
  alfresco     = "0.0.9"
  logstash     = "1.0.1"
  elasticbeats = "1.0.1"
  solr         = "patch/dev-solr-role"
  esadmin      = "0.0.6"
}
