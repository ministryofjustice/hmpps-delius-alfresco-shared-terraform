#!/bin/bash
set -x
# Install additional packages
sudo yum install -y amazon-efs-utils nfs-utils jq amazon-cloudwatch-agent unzip
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

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<- EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/dmesg",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/dmesg",
            "retention_in_days": -1
          },
          {
            "file_path": "/var/log/ecs/audit.log.*",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/ecs-audit",
            "retention_in_days": -1,
            "timestamp_format": "%Y-%m-%dT%H:%M:%SZ"
          },
          {
            "file_path": "/var/log/ecs/ecs-agent.log.*",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/ecs-agent",
            "retention_in_days": -1,
            "timestamp_format": "%Y-%m-%dT%H:%M:%SZ"
          },
          {
            "file_path": "/var/log/ecs/ecs-init.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/ecs-init",
            "retention_in_days": -1,
            "timestamp_format": "%Y-%m-%dT%H:%M:%SZ"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/messages",
            "retention_in_days": -1,
            "timestamp_format": "%b %d %H:%M:%S"
          }
        ]
      }
    }
  },
  "metrics": {
    "append_dimensions": {
      "AutoScalingGroupName": "\$${aws:AutoScalingGroupName}",
      "InstanceId": "\$${aws:InstanceId}"
    },
    "metrics_collected": {
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent

sudo systemctl restart docker
# ECS service is started by cloud-init once this userdata script has returned
