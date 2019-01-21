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
  src: singleplatform-eng.users

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

# Docker setup
cp /usr/share/zoneinfo/Europe/London /etc/localtime

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

# Add Postgres container

echo '[Unit]
Description=postgres container
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=-/etc/sysconfig/postgres
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/docker stop postgres
ExecStartPre=-/usr/bin/docker rm postgres
ExecStartPre=-/usr/bin/docker pull postgres:9.4-alpine
ExecStart=/usr/bin/docker run --name postgres \
  -p 5432:5432 \
  -e "TZ=Europe/London" \
  -e "POSTGRES_USER=${POSTGRES_USER}" \
  -e "POSTGRES_DB=${POSTGRES_DB}" \
  -e "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" postgres:9.4-alpine
ExecStop=-/usr/bin/docker rm -f postgres

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/postgres.service

touch /etc/sysconfig/postgres

systemctl daemon-reload

systemctl enable postgres.service
systemctl start postgres.service