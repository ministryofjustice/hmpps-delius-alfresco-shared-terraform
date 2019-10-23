#!/bin/bash
set -x
# packages
sudo yum install -y amazon-efs-utils nfs-utils jq awslogs httpd-tools

# kibana
sudo groupadd -g 3999 elasticsearch
sudo useradd -m -c elasticsearch -u 3999 -g elasticsearch elasticsearch

# efs
sudo mkdir /efs
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_endpoint}:/ /efs
sudo mkdir -p /efs/kibana/data /opt/kibana ${es_home_dir}/conf.d
sudo chown -R elasticsearch:elasticsearch /opt/kibana ${es_home_dir}
sudo chmod 777 /efs /efs/kibana /efs/kibana/data ${es_home_dir}

# elk

# htpasswd
ELK_USER_SSM_NAME=$(aws ssm get-parameters --with-decryption --region ${region} --names "${elk_user}" --query "Parameters[0]"."Value" --output text)

ELK_PASSWORD_SSM_NAME=$(aws ssm get-parameters --with-decryption --region ${region} --names "${elk_password}" --query "Parameters[0]"."Value" --output text)

echo "$ELK_PASSWORD_SSM_NAME" | htpasswd -i -c nginx_htpasswd $ELK_USER_SSM_NAME

sudo mv nginx_htpasswd /opt/kibana/htpasswd
sudo chown root:root /opt/kibana/htpasswd

## elasticsearch kibana confd
echo "cluster.name: ${es_cluster_name}
node.master: false
node.data: false
node.ingest: false
network.host: localhost
path.data: ${es_home_dir}/data
discovery.zen.minimum_master_nodes: ${es_master_nodes}
network.publish_host: _ec2:privateIp_
bootstrap.memory_lock: true
discovery.zen.hosts_provider: ec2
discovery.ec2.tag.es_cluster_discovery: ${es_cluster_name}
discovery.ec2.availability_zones: eu-west-2c,eu-west-2b,eu-west-2a
discovery.ec2.any_group: true
discovery.ec2.host_type: private_ip
cloud.node.auto_attributes: true
cluster.routing.allocation.awareness.attributes: aws_availability_zone
discovery.ec2.endpoint: ec2.eu-west-2.amazonaws.com" | sudo tee ${es_home_dir}/conf.d/kibana.yml

echo "[supervisord]
nodaemon=true
logfile_maxbytes=0
logfile=/dev/stdout

[supervisorctl]
serverurl = unix:///tmp/supervisor.sock

[unix_http_server]
file = /tmp/supervisor.sock

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[program:kibana]
command=/opt/kibana/bin/kibana
autorestart=true
redirect_stderr=true
stdout_logfile_maxbytes = 0
stdout_logfile = /dev/stdout" | sudo tee /opt/kibana/supervisord.conf

sudo chown -R elasticsearch:elasticsearch /opt/kibana ${es_home_dir}


echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/elasticsearch.conf

sudo sysctl -p --system

sudo sh -c "ulimit -n 65536"
sudo sh -c "ulimit -u 2048"
sudo sh -c "ulimit -l unlimited"

echo "# allow user 'elasticsearch' mlockall
elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited
elasticsearch  -  nofile  65536" | sudo tee /etc/security/limits.d/elasticsearch.conf

# ECS agent configuration
echo "ECS_CLUSTER=${es_cluster_name}
ECS_AWSVPC_BLOCK_IMDS=true
ECS_ENABLE_TASK_ENI=true" >> /etc/ecs/ecs.config

# Logs configuration
export INSTANCE_ID="$(curl http://169.254.169.254/latest/meta-data/instance-id)"
cat > /etc/awslogs/awslogs.conf <<- EOF
[general]
state_file = /var/lib/awslogs/agent-state

[/var/log/dmesg]
file = /var/log/dmesg
log_group_name = ${log_group_name}
log_stream_name = $INSTANCE_ID/dmesg

[/var/log/messages]
file = /var/log/messages
log_group_name = ${log_group_name}
log_stream_name = $INSTANCE_ID/messages
datetime_format = %b %d %H:%M:%S

[/var/log/docker]
file = /var/log/docker
log_group_name = ${log_group_name}
log_stream_name = $INSTANCE_ID/docker
datetime_format = %Y-%m-%dT%H:%M:%S.%f

[/var/log/ecs/ecs-init.log]
file = /var/log/ecs/ecs-init.log
log_group_name = ${log_group_name}
log_stream_name = $INSTANCE_ID/ecs-init
datetime_format = %Y-%m-%dT%H:%M:%SZ

[/var/log/ecs/ecs-agent.log]
file = /var/log/ecs/ecs-agent.log.*
log_group_name = ${log_group_name}
log_stream_name = $INSTANCE_ID/ecs-agent
datetime_format = %Y-%m-%dT%H:%M:%SZ

[/var/log/ecs/audit.log]
file = /var/log/ecs/audit.log.*
log_group_name = ${log_group_name}
log_stream_name = $INSTANCE_ID/ecs-audit
datetime_format = %Y-%m-%dT%H:%M:%SZ

EOF

sed -i -e "s/region = us-east-1/region = ${region}/g" /etc/awslogs/awscli.conf

sudo systemctl enable awslogsd.service
sudo systemctl start awslogsd
