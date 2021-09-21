#!/bin/bash
set -x
# Install additional packages
sudo yum install -y amazon-efs-utils nfs-utils jq awslogs unzip
# Install and start SSM Agent service - will always want the latest - used for remote access via aws console/cli
# Avoids need to manage users identity in 2 places and install ansible/dependencies
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Install the X-Ray Java Agent
curl --location 'https://github.com/aws/aws-xray-java-agent/releases/latest/download/xray-agent.zip' --output /xray-agent.zip
unzip /xray-agent.zip -d /xray-agent
rm -f /xray-agent.zip
# Install the AWS OpenTelemetry Agent
curl --location 'https://github.com/aws-observability/aws-otel-java-instrumentation/releases/latest/download/aws-opentelemetry-agent.jar' --output /xray-agent/aws-opentelemetry-agent.jar

# Install the Prometheus JMX Exporter
mkdir -p /jmx-exporter
curl --location 'https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.16.1/jmx_prometheus_javaagent-0.16.1.jar' --output /jmx-exporter/jmx_prometheus_javaagent.jar
echo -e 'lowercaseOutputName: true\nlowercaseOutputLabelNames: true' > /jmx-exporter/config.yaml

# Install any docker plugins
# Volume plugin for providing EBS/EFS docker volumes
docker plugin install rexray/efs REXRAY_PREEMPT=true EFS_REGION=${region} EFS_SECURITYGROUPS=${efs_sg} --grant-all-permissions
docker plugin install rexray/ebs \
    LINUX_VOLUME_FILEMODE=0777 \
    REXRAY_PREEMPT=true \
    EBS_REGION=${region} \
    EBS_KMSKEYID=${kms_key_arn} \
    --grant-all-permissions

# Set any ECS agent configuration options
echo "ECS_CLUSTER=${ecs_cluster_name}" >> /etc/ecs/ecs.config
# Block tasks running in awsvpc mode from calling host metadata
echo "ECS_AWSVPC_BLOCK_IMDS=true" >> /etc/ecs/ecs.config
# Required for ecs tasks in awsvpc mode to pull images remotely
echo "ECS_ENABLE_TASK_ENI=true" >> /etc/ecs/ecs.config
# Enabled log drivers
echo "ECS_AVAILABLE_LOGGING_DRIVERS=[\"awslogs\",\"fluentd\"]" >> /etc/ecs/ecs.config

# Inject the CloudWatch Logs configuration file contents
export INSTANCE_ID="`curl http://169.254.169.254/latest/meta-data/instance-id`"
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

# Set the region to send CloudWatch Logs data to (the region where the container instance is located)
sed -i -e "s/region = us-east-1/region = ${region}/g" /etc/awslogs/awscli.conf

# Start the awslogs service
sudo systemctl enable awslogsd.service
sudo systemctl start awslogsd
sudo systemctl restart docker
# ECS service is started by cloud-init once this userdata script has returned
