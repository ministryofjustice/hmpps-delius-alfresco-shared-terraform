#!/bin/bash
set -x
# packages
sudo yum install -y amazon-efs-utils nfs-utils jq awslogs

# efs
sudo mkdir /efs
sudo mkdir -p /efs/kibana/${svc_name}/data /opt/kibana
sudo chmod 777 /efs /efs/kibana /efs/kibana/${svc_name}/data

echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/elasticsearch.conf

sudo sysctl -p --system

sudo sh -c "ulimit -n 65536"
sudo sh -c "ulimit -u 2048"
sudo sh -c "ulimit -l unlimited"

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
