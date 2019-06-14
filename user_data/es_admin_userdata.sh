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
pip install ansible

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
EOF

wget https://raw.githubusercontent.com/ministryofjustice/hmpps-delius-ansible/master/group_vars/${bastion_inventory}.yml -O users.yml

cat << EOF > ~/bootstrap.yml
---
- hosts: localhost
  vars_files:
   - "{{ playbook_dir }}/users.yml"
  roles:
     - bootstrap
     - rsyslog
     - users
EOF

ansible-galaxy install -f -r ~/requirements.yml
HAS_DOCKER=true ansible-playbook ~/bootstrap.yml

# add elasticsearch user

groupadd -g 3999 elasticsearch

useradd -m -g elasticsearch -u 3999 elasticsearch

mkdir -p ${es_home_dir}/data ${es_home_dir}/logs ${es_home_dir}/config /opt/scripts /opt/local /opt/es_backups

# container sync scripts
echo "#!/bin/bash
aws s3 sync s3://${es-bucket}/scripts /opt/scripts" > /opt/scripts/sync-scripts.sh
chmod +x /opt/scripts/sync-scripts.sh

# set perms
chown -R elasticsearch:elasticsearch ${es_home_dir} ${efs_mount_path} /opt/scripts /opt/local /opt/es_backups

# ES settings
echo "vm.max_map_count=262144" > /etc/sysctl.d/elasticsearch.conf

sysctl -p

ulimit -n 65536
ulimit -u 2048
ulimit -l unlimited


# NFS
yum install -y nfs-utils

mkdir -p ${efs_mount_path} ${es_home_dir}

mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${efs_dns_name}:/ ${efs_mount_path}

# docker tls
docker_tls_dir=/opt/docker
docker_key_file=$docker_tls_dir/server.key
docker_cert_file=$docker_tls_dir/server.cert
docker_ca_cert_file=$docker_tls_dir/ca.cert

mkdir -p $docker_tls_dir 

aws ssm get-parameters --with-decryption --names ${ssm_tls_private_key} --region ${region} --query "Parameters[0]"."Value" --output text > $docker_key_file
aws ssm get-parameters --names ${ssm_tls_ca_cert} --region ${region} --query "Parameters[0]"."Value" --output text > $docker_ca_cert_file
aws ssm get-parameters --names ${ssm_tls_cert} --region ${region} --query "Parameters[0]"."Value" --output text > $docker_cert_file


chown -R root:docker $docker_tls_dir

chmod -R 660 $docker_tls_dir
chmod 440 $docker_key_file


docker_systemd_dir=/etc/systemd/system/docker.service.d
custom_conf=$docker_systemd_dir/custom.conf
mkdir -p $docker_systemd_dir

echo "[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock -H=0.0.0.0:2376 --tlsverify --tlscacert=$docker_ca_cert_file --tlscert=$docker_cert_file --tlskey=$docker_key_file" > $custom_conf

systemctl daemon-reload

systemctl restart docker