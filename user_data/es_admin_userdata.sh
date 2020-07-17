#!/usr/bin/env bash

yum install -y python-pip git wget unzip

cat << EOF >> /etc/environment
HMPPS_ROLE=${app_name}
HMPPS_FQDN=${app_name}.${private_domain}
HMPPS_STACKNAME=${env_identifier}
HMPPS_STACK="${short_env_identifier}"
HMPPS_ENVIRONMENT=${environment_name}
HMPPS_ACCOUNT_ID="${account_id}"
HMPPS_DOMAIN="${private_domain}"
EOF
## Ansible runs in the same shell that has just set the env vars for future logins so it has no knowledge of the vars we've
## just configured, so lets export them
export HMPPS_ROLE="${app_name}"
export HMPPS_FQDN="${app_name}.${private_domain}"
export HMPPS_STACKNAME="${env_identifier}"
export HMPPS_STACK="${short_env_identifier}"
export HMPPS_ENVIRONMENT=${environment_name}
export HMPPS_ACCOUNT_ID="${account_id}"
export HMPPS_DOMAIN="${private_domain}"

cd ~
pip install -U ansible

cat << EOF > ~/requirements.yml
- name: bootstrap
  src: https://github.com/ministryofjustice/hmpps-bootstrap
  version: centos
- name: rsyslog
  src: https://github.com/ministryofjustice/hmpps-rsyslog-role
- name: elasticbeats
  src: https://github.com/ministryofjustice/hmpps-beats-monitoring
- name: users
  src: singleplatform-eng.users
- name: ansible-esadmin-role
  src: https://github.com/ministryofjustice/hmpps-ansible-esadmin-role
  version: "${esadmin_version}"
EOF

cat << EOF > ~/bootstrap_vars.yml
---
- remote_user_filename: "${bastion_inventory}"
- config_bucket: "${config-bucket}"
- esadmin_user: elasticsearch
- esadmin_gid: 3999
- alf_backup_bucket: "${alf_backup_bucket}"
- alf_storage_bucket: "${alf_storage_bucket}"
- generate_certs: true
- docker_tls: true
- aws_region: eu-west-2
- ssm_prefix: "alfresco/esadmin/docker"
- docker_host: "${docker_host}"
- mount_point: "${mount_point}"
- log_group: ${log_group}
- log_stream: ci
EOF

wget https://raw.githubusercontent.com/ministryofjustice/hmpps-delius-ansible/master/group_vars/${bastion_inventory}.yml -O users.yml

cat << EOF > ~/bootstrap.yml
---
- hosts: localhost
  gather_facts: true
  vars_files:
     - "{{ playbook_dir }}/bootstrap_vars.yml"
     - "{{ playbook_dir }}/users.yml"
  roles:
     - bootstrap
     - rsyslog
     - users
     - ansible-esadmin-role
EOF

ansible-galaxy install -f -r ~/requirements.yml
ansible-playbook ~/bootstrap.yml

chmod -R 0770 ${mount_point}
