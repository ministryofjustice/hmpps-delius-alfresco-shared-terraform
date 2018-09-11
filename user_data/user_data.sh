#!/usr/bin/env bash

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
  version: centos
- name: rsyslog
  src: https://github.com/ministryofjustice/hmpps-rsyslog-role
- name: elasticbeats
  src: https://github.com/ministryofjustice/hmpps-beats-monitoring
- name: alfresco
  src: https://github.com/ministryofjustice/hmpps-alfresco-bootstrap
EOF

cat << EOF > ~/bootstrap.yml
---

- hosts: localhost
  roles:
     - bootstrap
     - rsyslog
     - elasticbeats
     - alfresco
EOF

ansible-galaxy install -f -r ~/requirements.yml
SELF_REGISTER=true ansible-playbook ~/bootstrap.yml \
    -e mount_point="${cache_home}" \
    -e device_name="${ebs_device}" \
    -e monitoring_host="${monitoring_server_url}" \
    -e bucket_name="${bucket_name}"  \
    -e bucket_encrypt_type="${bucket_encrypt_type}"  \
    -e bucket_key_id="${bucket_key_id}"  \
    -e db_user="${db_user}"  \
    -e db_password="${db_password}"  \
    -e db_name="${db_name}"  \
    -e db_host="${db_host}"  \
    -e server_mode="${server_mode}"  \
    -e cluster_name="${cluster_name}"  \
    -e cluster_subnet="${cluster_subnet}"  \
    -e monitoring_server_url="${monitoring_server_url}"  \
    -e monitoring_cluster_name="${monitoring_cluster_name}" \
    -e cldwatch_log_group="${cldwatch_log_group}" \
    -e region="${region}" \
    -e external_fqdn="${external_fqdn}" \
    -e alfresco_protocol="https" \
    -e alfresco_port="443" \
    -e cluster_enabled="true"

# Currently there is a bit of oddness with the service startup, it seems we have to restart it for Alfresco to be available
sudo service tomcat-alfresco stop
sleep 10
sudo service tomcat-alfresco start

