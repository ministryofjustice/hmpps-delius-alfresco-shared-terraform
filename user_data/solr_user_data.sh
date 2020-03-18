#!/usr/bin/env bash

yum install -y git wget python-pip
pip install -U pip
pip install ansible

logger "yum install stage complete"

cat << EOF >> /etc/environment
HMPPS_ROLE=${app_name}
HMPPS_FQDN="`curl http://169.254.169.254/latest/meta-data/instance-id`.${private_domain}"
HMPPS_STACKNAME=${env_identifier}
HMPPS_STACK="${short_env_identifier}"
HMPPS_ENVIRONMENT=${route53_sub_domain}
HMPPS_ACCOUNT_ID="${account_id}"
HMPPS_DOMAIN="${private_domain}"
JAVA_HOME=/usr/java/jdk1.8.0_181-amd64/jre
EOF
## Ansible runs in the same shell that has just set the env vars for future logins so it has no knowledge of the vars we've
## just configured, so lets export them
export HMPPS_ROLE="${app_name}"
export HMPPS_FQDN="`curl http://169.254.169.254/latest/meta-data/instance-id`.${private_domain}"
export HMPPS_STACKNAME="${env_identifier}"
export HMPPS_STACK="${short_env_identifier}"
export HMPPS_ENVIRONMENT=${route53_sub_domain}
export HMPPS_ACCOUNT_ID="${account_id}"
export HMPPS_DOMAIN="${private_domain}"
export JAVA_HOME=/usr/java/jdk1.8.0_181-amd64/jre

cat << EOF > ~/requirements.yml
---
- name: bootstrap
  src: https://github.com/ministryofjustice/hmpps-bootstrap
  version: ${bootstrap_version}
- name: elasticbeats
  src: https://github.com/ministryofjustice/hmpps-beats-monitoring
  version: ${elasticbeats_version}
- name: logstash
  src: https://github.com/ministryofjustice/hmpps-logstash
  version: ${logstash_version}
- name: alfresco
  src: https://github.com/ministryofjustice/hmpps-alfresco-bootstrap
  version: ${alfresco_version}


- name: bootstrap
  src: https://github.com/ministryofjustice/hmpps-bootstrap
  version: ${bootstrap_version}
- name: elasticbeats
  src: https://github.com/ministryofjustice/hmpps-beats-monitoring
  version: ${elasticbeats_version}
- name: logstash
  src: https://github.com/ministryofjustice/hmpps-logstash
  version: ${logstash_version}
- name: alfresco
  src: https://github.com/ministryofjustice/hmpps-alfresco-bootstrap
  version: ${alfresco_version}
- name: users
  src: singleplatform-eng.users
- name: solr
  src: https://github.com/ministryofjustice/hmpps-ansible-role-solr.git
  version: ${solr_version}
EOF

cat << EOF > ~/bootstrap_vars.yml
- mount_point: "${cache_home}"
- device_name: "${ebs_device}"
- logstash_host: "${logstash_host_fqdn}"
- kibana_host: "${kibana_host_fqdn}"
- monitoring_host: "${monitoring_server_url}"
- elasticsearch_ssl: "true"
- internal_domain: "${private_domain}"
- bucket_name: "${bucket_name}" 
- bucket_encrypt_type: "${bucket_encrypt_type}"
- bucket_key_id: "${bucket_key_id}"
- db_user: "{{ lookup('aws_ssm', '${db_user}', region='${region}') }}"
- db_password: "{{ lookup('aws_ssm', '${db_password}', decrypt=True, region='${region}') }}"
- db_name: "${db_name}"
- db_host: "${db_host}"
- cluster_name: "${cluster_name}"
- cluster_subnet: "${cluster_subnet}"
- monitoring_server_url: "${monitoring_server_url}"
- monitoring_cluster_name: "${monitoring_cluster_name}"
- cldwatch_log_group: "${cldwatch_log_group}"
- region: "${region}"
- external_fqdn: "${external_fqdn}"
- alfresco_protocol: "http"
- alfresco_port: "8080"
- cluster_enabled: "true"
- messaging_broker_url: "${messaging_broker_url}"
- messaging_broker_password: "{{ lookup('aws_ssm', '${messaging_broker_password}', decrypt=True, region='${region}') }}"
- remote_user_filename: "${bastion_inventory}"
- logstash_version: "5.6.15"
- tomcat_maxthreads: "150"
- solr_port: "${solr_port}"
- solr_device_name: "${solr_device_name}"
- solr_volume_name: "${solr_volume_name }"
- solr_java_xms: "${solr_java_xms}"
- solr_java_xmx: "${solr_java_xmx}"
- alfresco_server_allow_write: "false"
- solr_stream_logs: "enabled"
- solr_backups_enabled: true
- solr_backups_bucket: "${backups_bucket}"
- solr_index: true
- dns_zone_id: "${private_zone_id}"
- solr_dns_record: "solr"
- dns_zone_name: "${internal_domain}"
EOF

wget https://raw.githubusercontent.com/ministryofjustice/hmpps-delius-ansible/master/group_vars/${bastion_inventory}.yml -O ~/users.yml

cat << EOF > ~/bootstrap.yml
---

- hosts: localhost
  vars_files:
    - "{{ playbook_dir }}/bootstrap_vars.yml"
    - "{{ playbook_dir }}/users.yml"
  roles:
    - bootstrap
    - elasticbeats
    - logstash
    - users
    - alfresco
    - solr
EOF

logger "ansible prep stage complete"

ansible-galaxy install -f -r ~/requirements.yml | logger
SELF_REGISTER=true ansible-playbook ~/bootstrap.yml | logger

logger "ansible playbook stage complete"

# Currently there is a bit of oddness with the service startup, it seems we have to restart it for Alfresco to be available
export DATE=$(date +"%F-%H-%M")
cp /etc/sysconfig/tomcat /etc/sysconfig/tomcat-$DATE
echo 'JAVA_OPTS="-XmsMEMORY_REPLACE -XmxMEMORY_REPLACE -XX:PermSize=192m -XX:NewSize=512m -XX:MaxPermSize=1G \
  -XX:NewRatio=4 -XX:+UseParNewGC -XX:+UseCodeCacheFlushing -XX:+DisableExplicitGC \
  -XX:InitialCodeCacheSize=256m -XX:ReservedCodeCacheSize=256m -XX:+UseConcMarkSweepGC \
  -XX:+CMSParallelRemarkEnabled -XX:CMSInitiatingOccupancyFraction=80 -Dsun.rmi.dgc.client.gcInterval=3600000 \
  -Dsun.rmi.dgc.server.gcInterval=3600000 -server -Dsun.security.ssl.allowUnsafeRenegotiation=true -Duser.timezone=UTC \
  -Dsun.security.krb5.msinterop.kstring=true"' > /etc/sysconfig/tomcat

sed -i 's/MEMORY_REPLACE/${jvm_memory}/g' /etc/sysconfig/tomcat

chown -R tomcat:tomcat /srv/cache

logger "alfresco sysconfig stage complete"

# start tomcat service
sudo systemctl stop tomcat
sudo systemctl start tomcat

logger "alfresco bootstrap complete"

# restart awslogs
systemctl restart awslogs