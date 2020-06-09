#!/usr/bin/env bash

yum install -y python-pip git wget unzip

cat << EOF >> /etc/environment
HMPPS_ROLE=es-admin
HMPPS_FQDN=es-admin.alfresco-dev.internal
HMPPS_STACKNAME=tf-alfresco-dev
HMPPS_STACK="tf-alf-dev"
HMPPS_ENVIRONMENT=alfresco-dev
HMPPS_ACCOUNT_ID="563502482979"
HMPPS_DOMAIN="alfresco-dev.internal"
EOF
## Ansible runs in the same shell that has just set the env vars for future logins so it has no knowledge of the vars we've
## just configured, so lets export them
export HMPPS_ROLE="es-admin"
export HMPPS_FQDN="es-admin.alfresco-dev.internal"
export HMPPS_STACKNAME="tf-alfresco-dev"
export HMPPS_STACK="tf-alf-dev"
export HMPPS_ENVIRONMENT=alfresco-dev
export HMPPS_ACCOUNT_ID="563502482979"
export HMPPS_DOMAIN="alfresco-dev.internal"

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
  version: "0.0.5"
EOF

cat << EOF > ~/bootstrap_vars.yml
---
- remote_user_filename: "${bastion_inventory}"
- config_bucket: "${config-bucket}"
- esadmin_user: elasticsearch
- esadmin_gid: 3999
- alf_backup_bucket: "${alf_backup_bucket}"
- alf_storage_bucket: "${alf_storage_bucket}"
- generate_certs: false
- docker_tls: false
- aws_region: eu-west-2
- manage_storage: false
- redis_host: ${redis_host}
EOF

wget https://raw.githubusercontent.com/ministryofjustice/hmpps-delius-ansible/master/group_vars/dev.yml -O users.yml

cat << EOF > ~/bootstrap.yml
---
- hosts: localhost
  vars_files:
     - "{{ playbook_dir }}/bootstrap_vars.yml"
     - "{{ playbook_dir }}/users.yml"
  roles:
    #  - bootstrap
    #  - users
     - ansible-esadmin-role
EOF

ansible-galaxy install -f -r ~/requirements.yml
ansible-playbook ~/bootstrap.yml

chmod -R 0770 /opt/eslocal
