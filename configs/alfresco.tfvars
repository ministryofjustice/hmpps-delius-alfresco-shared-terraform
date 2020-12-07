# ASG Configuration
alf_config_map = {
  asg_ami  = "ami-072548d2dd6688dde"
  ami_name = "HMPPS Alfresco *"
  image_id = "ami-072548d2dd6688dde"
}

source_code_versions = {
  boostrap     = "centos"
  alfresco     = "0.0.8"
  logstash     = "1.0.1"
  elasticbeats = "1.0.1"
  solr         = "0.0.5"
  esadmin      = "0.0.6"
}
