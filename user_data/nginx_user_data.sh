#!/bin/bash

Content-Type: multipart/mixed; boundary="==BOUNDARY=="
MIME-Version: 1.0

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash

# Set any ECS agent configuration options
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
service docker start
start ecs

# Install awslogs and the jq JSON parser
yum install -y awslogs jq

mkdir -p /var/log/${container_name}

# Inject the CloudWatch Logs configuration file contents
cat > /etc/awslogs/awslogs.conf <<- EOF
[general]
state_file = /var/lib/awslogs/agent-state

[application_log]
file = /var/log/${container_name}/*.log
log_group_name = ${log_group_name}
log_stream_name = {hostname}/{container_instance_id}/application

[/var/log/dmesg]
file = /var/log/dmesg
log_group_name = ${log_group_name}
log_stream_name = {hostname}/{container_instance_id}/dmesg_logs

[/var/log/messages]
file = /var/log/messages
log_group_name = ${log_group_name}
log_stream_name = {hostname}/{container_instance_id}/messages
datetime_format = %b %d %H:%M:%S

[/var/log/docker]
file = /var/log/docker
log_group_name = ${log_group_name}
log_stream_name = {hostname}/{container_instance_id}/docker
datetime_format = %Y-%m-%dT%H:%M:%S.%f

[/var/log/ecs/ecs-init.log]
file = /var/log/ecs/ecs-init.log
log_group_name = ${log_group_name}
log_stream_name = {hostname}/{container_instance_id}/ecsinit_logs
datetime_format = %Y-%m-%dT%H:%M:%SZ

[/var/log/ecs/ecs-agent.log]
file = /var/log/ecs/ecs-agent.log
log_group_name = ${log_group_name}
log_stream_name = {hostname}/{container_instance_id}/ecsagent_logs
datetime_format = %Y-%m-%dT%H:%M:%SZ

[/var/log/ecs/audit.log]
file = /var/log/ecs/audit.log
log_group_name = ${log_group_name}
log_stream_name = {hostname}/{container_instance_id}/ecsaudit_logs
datetime_format = %Y-%m-%dT%H:%M:%SZ
EOF

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
# Set the region to send CloudWatch Logs data to (the region where the container instance is located)
region=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
sed -i -e "s/region = us-east-1/region = $region/g" /etc/awslogs/awscli.conf

# log into AWS ECR
aws ecr get-login --no-include-email --region $region

--==BOUNDARY==
Content-Type: text/upstart-job; charset="us-ascii"

#upstart-job
description "Configure and start CloudWatch Logs agent on Amazon ECS container instance"
author "Amazon Web Services"
start on started ecs

script
    exec 2>>/var/log/ecs/cloudwatch-logs-start.log
    set -x

    until curl -s http://localhost:51678/v1/metadata
    do
        sleep 1
    done

# Grab the cluster and container instance ARN from instance metadata
host_name=$(hostname -s)
cluster=$(curl -s http://localhost:51678/v1/metadata | jq -r '. | .Cluster')
container_instance_id=${container_name}
avail_zone=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)

# Replace the cluster name and container instance ID placeholders with the actual values
sed -i -e "s/{container_instance_id}/$container_instance_id/g" /etc/awslogs/awslogs.conf
sed -i -e "s/{availzone}/$avail_zone/g" /etc/awslogs/awslogs.conf
sed -i -e "s/{hostname}/$host_name/g" /etc/awslogs/awslogs.conf

service awslogs start
chkconfig awslogs on
end script

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
# Mount our EBS volume on boot

cp /usr/share/zoneinfo/Europe/London /etc/localtime

mkdir -p ${keys_dir}

pvcreate ${ebs_device}

vgcreate data ${ebs_device}

lvcreate -l100%VG -n keys data

mkfs.xfs /dev/data/keys

echo "/dev/mapper/data-keys ${keys_dir} xfs defaults 0 0" >> /etc/fstab

mount -a

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


end script