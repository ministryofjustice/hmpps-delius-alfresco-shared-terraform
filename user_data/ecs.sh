#!/usr/bin/env bash

yum install -y python-pip git wget

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
ansible-playbook ~/bootstrap.yml

# ECS config
sed -i 's/ECS_CLUSTER=default/ECS_CLUSTER=${ecs_cluster}/g' /etc/ecs/ecs.config

# NFS
yum install -y nfs-utils

mkdir -p ${efs_mount_path} ${es_home_dir}

mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${efs_dns_name}:/ ${efs_mount_path}

# create lvm and mount
pvcreate /dev/xvdb
vgcreate esdata /dev/xvdb
lvcreate -n esdatavol -l90%VG esdata
mkfs.xfs -f /dev/esdata/esdatavol

cat /etc/fstab | grep -v '/dev/esdata/esdatavol' > /tmp/fstab-orig
cat /tmp/fstab-orig > /etc/fstab

echo "/dev/esdata/esdatavol    ${es_home_dir}  xfs defaults 0 0" >> /etc/fstab

mount -a

# add elasticsearch user

groupadd -g 1000 elasticsearch

useradd -m -g elasticsearch -u 1000 elasticsearch

mkdir -p ${es_home_dir}/data ${es_home_dir}/logs ${es_home_dir}/config

chown -R elasticsearch:elasticsearch ${es_home_dir} ${efs_mount_path}

# config
host_name=$(hostname)
host_ip=$(hostname -i)
echo "discovery.type: ${es_discovery_type}
network:
  host: 0.0.0.0
  publish_host: $host_ip
path:
  logs: ${es_home_dir}/logs
  data: ${es_home_dir}/data
  repo: ["${efs_mount_path}"]
bootstrap.memory_lock: true
node.name: $host_name
cluster.name: ${ecs_cluster}" > ${es_home_dir}/config/elasticsearch.yml

echo "vm.max_map_count=262144" > /etc/sysctl.d/elasticsearch.conf

sysctl -p

ulimit -n 65536
ulimit -u 2048
ulimit -l unlimited

service docker restart

#restart ecs-agent
docker rm -f ecs-agent

docker run --name ecs-agent \
    --detach=true \
    --restart=on-failure:10 \
    --volume=/var/run:/var/run \
    --volume=/var/log/ecs/:/log \
    --volume=/var/lib/ecs/data:/data \
    --volume=/etc/ecs:/etc/ecs \
    --net=host \
    --env-file=/etc/ecs/ecs.config \
    amazon/amazon-ecs-agent:latest