#!/usr/bin/env bash

yum install -y git wget python-pip
pip install -U pip
pip install ansible

cat << EOF >> /etc/environment
HMPPS_ROLE=${app_name}
HMPPS_FQDN="`curl http://169.254.169.254/latest/meta-data/instance-id`.${internal_domain}"
HMPPS_STACKNAME=${env_identifier}
HMPPS_STACK="${short_env_identifier}"
HMPPS_ENVIRONMENT=${route53_sub_domain}
HMPPS_ACCOUNT_ID="${account_id}"
HMPPS_DOMAIN="${internal_domain}"
EOF
## Ansible runs in the same shell that has just set the env vars for future logins so it has no knowledge of the vars we've
## just configured, so lets export them
export HMPPS_ROLE="${app_name}"
export HMPPS_FQDN="`curl http://169.254.169.254/latest/meta-data/instance-id`.${internal_domain}"
export HMPPS_STACKNAME="${env_identifier}"
export HMPPS_STACK="${short_env_identifier}"
export HMPPS_ENVIRONMENT=${route53_sub_domain}
export HMPPS_ACCOUNT_ID="${account_id}"
export HMPPS_DOMAIN="${internal_domain}"

cat << EOF > ~/requirements.yml
---

- name: bootstrap
  src: https://github.com/ministryofjustice/hmpps-bootstrap
  version: centos
- name: users
  src: https://github.com/singleplatform-eng/ansible-users

EOF

wget https://raw.githubusercontent.com/ministryofjustice/hmpps-delius-ansible/master/group_vars/${bastion_inventory}.yml -O ~/users.yml

cat << EOF > ~/bootstrap.yml
---

- hosts: localhost
  vars_files:
    - "{{ playbook_dir }}/users.yml"
  roles:
    - bootstrap
    - users
EOF

ansible-galaxy install -f -r ~/requirements.yml
SELF_REGISTER=true ansible-playbook ~/bootstrap.yml

# Install awslogs and the jq JSON parser
current_dir=$(pwd)
region=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)

mkdir -p /tmp/awslogs-install
cd /tmp/awslogs-install
curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O

mkdir -p /var/log/${container_name}

# Inject the CloudWatch Logs configuration file contents
cat > awslogs.conf <<- EOF
[general]
state_file = /var/awslogs/state/agent-state

[/var/log/messages]
datetime_format = %b %d %H:%M:%S
file = /var/log/messages
buffer_duration = 5000
log_stream_name = {instance_id}/messages
initial_position = start_of_file
log_group_name = ${log_group_name}

[/var/log/audit/audit.log]
datetime_format = %b %d %H:%M:%S
file = /var/log/audit/audit.log
buffer_duration = 5000
log_stream_name = {instance_id}/audit
initial_position = start_of_file
log_group_name = ${log_group_name}

[/var/log/secure]
datetime_format = %b %d %H:%M:%S
file = /var/log/secure
buffer_duration = 5000
log_stream_name = {instance_id}/secure
initial_position = start_of_file
log_group_name = ${log_group_name}

[/var/log/cloud-init.log]
datetime_format = %b %d %H:%M:%S
file = /var/log/cloud-init.log
buffer_duration = 5000
log_stream_name = {instance_id}/cloud-init.log
initial_position = start_of_file
log_group_name = ${log_group_name}

EOF

python ./awslogs-agent-setup.py --region $region --non-interactive --configfile=awslogs.conf

# Set the region to send CloudWatch Logs data to (the region where the container instance is located)
region=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)

# log into AWS ECR
aws ecr get-login --no-include-email --region $region

systemctl daemon-reload
systemctl enable awslogs
systemctl start awslogs
# end script

cd $current_dir

rm -rf /tmp/awslogs-install

cp /usr/share/zoneinfo/Europe/London /etc/localtime

mkdir -p ${keys_dir}

# GET SECRETS FROM PARAMETER STORE
${ssm_get_command} "${self_signed_ca_cert}" \
    | jq -r '.Parameters[0].Value' > ${keys_dir}/ca.crt

${ssm_get_command} "${self_signed_key}" \
    --with-decryption | jq -r '.Parameters[0].Value' > ${keys_dir}/server.key

${ssm_get_command} "${self_signed_cert}" \
    --with-decryption | jq -r '.Parameters[0].Value' > ${keys_dir}/server.crt

cat ${keys_dir}/ca.crt >> ${keys_dir}/server.crt

chmod 600 ${keys_dir}

chmod 400 ${keys_dir}/server.key

chmod 600 ${keys_dir}/*crt

# Docker setup

echo '### DOCKER SETUP'

yum remove  -y docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-selinux \
    docker-engine-selinux \
    docker-engine

yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum install docker-ce docker-distribution -y

mkdir -p /etc/docker

echo '{
    "selinux-enabled": true,
    "log-driver": "journald",
    "storage-opts": [
      "dm.directlvm_device=${ebs_device}",
      "dm.thinp_percent=95",
      "dm.thinp_metapercent=1",
      "dm.thinp_autoextend_threshold=80",
      "dm.thinp_autoextend_percent=20",
      "dm.directlvm_device_force=false"
    ],
    "storage-driver": "devicemapper"
}' > /etc/docker/daemon.json

systemctl enable docker

systemctl restart docker

# Add nginx container

echo '[Unit]
Description=${container_name} nginx container
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=-/etc/sysconfig/proxy
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/docker stop ${container_name}
ExecStartPre=-/usr/bin/docker rm ${container_name}
ExecStartPre=-/usr/bin/docker pull ${image_url}:${image_version}
ExecStart=/usr/bin/docker run --name ${container_name} \
  -p 80:80 \
  -p 443:443 \
  -v ${keys_dir}:${keys_dir}:z \
  -e "TZ=Europe/London" \
  -e "S3_CONFIG_BUCKET=${s3_bucket_config}" \
  -e "ALFRESCO_HOST=${alfresco_host}" \
  -e "CONFIG_FILE_PATH=${config_file_path}" \
  -e "RUNTIME_CONFIG_OVERRIDE=${runtime_config_override}" \
  -e "TOMCAT_HOST=${tomcat_host}" \
  -e "KIBANA_HOST=${kibana_host}" \
  -e "NGINX_CONFIG_FILE=${nginx_config_file}" ${image_url}:${image_version}
ExecStop=-/usr/bin/docker rm -f ${container_name}

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/proxy.service

touch /etc/sysconfig/proxy

systemctl daemon-reload

systemctl enable proxy.service
systemctl start proxy.service

# fix for nginx dns caching
crontab -l > /tmp/crontab.job
echo '*    *    *    *    *    docker exec proxy nginx -s reload > /tmp/docker-cron-reload.log 2>&1' >> /tmp/crontab.job
crontab /tmp/crontab.job
rm -rf /tmp/crontab.job