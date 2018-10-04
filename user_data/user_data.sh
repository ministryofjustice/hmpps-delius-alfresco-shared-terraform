#!/usr/bin/env bash

yum install -y git wget python-pip
pip install -U pip
pip install ansible

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
- name: users
  src: singleplatform-eng.users

EOF

cat << EOF > ~/bootstrap_vars.yml
mount_point: "${cache_home}" \
device_name: "${ebs_device}" \
monitoring_host: "${monitoring_server_url}" \
bucket_name: "${bucket_name}"  \
bucket_encrypt_type: "${bucket_encrypt_type}"  \
bucket_key_id: "${bucket_key_id}"  \
db_user: "${db_user}"  \
db_password: "${db_password}"  \
db_name: "${db_name}"  \
db_host: "${db_host}"  \
server_mode: "${server_mode}"  \
cluster_name: "${cluster_name}"  \
cluster_subnet: "${cluster_subnet}"  \
monitoring_server_url: "${monitoring_server_url}"  \
monitoring_cluster_name: "${monitoring_cluster_name}" \
cldwatch_log_group: "${cldwatch_log_group}" \
region: "${region}" \
external_fqdn: "${external_fqdn}" \
alfresco_protocol: "https" \
alfresco_port: "443" \
cluster_enabled: "true"
EOF

wget https://raw.githubusercontent.com/ministryofjustice/hmpps-delius-ansible/master/group_vars/bastion -O users.yml

cat << EOF > ~/bootstrap.yml
---

- hosts: localhost
  vars_files:
    - "{{ playbook_dir }}/bootstrap_vars.yml"
    - "{{ playbook_dir }}/users.yml"
- hosts: localhost
  roles:
     - bootstrap
     - rsyslog
     - elasticbeats
     - users
     - alfresco
EOF

ansible-galaxy install -f -r ~/requirements.yml
SELF_REGISTER=true ansible-playbook ~/bootstrap.yml

# Currently there is a bit of oddness with the service startup, it seems we have to restart it for Alfresco to be available
sudo service tomcat-alfresco stop
sleep 10
sudo service tomcat-alfresco start

