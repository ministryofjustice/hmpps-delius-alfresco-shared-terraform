#!/bin/bash

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
EOF

# Set the region to send CloudWatch Logs data to (the region where the container instance is located)
region=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
sed -i -e "s/region = us-east-1/region = $region/g" /etc/awslogs/awscli.conf

# log into AWS ECR
aws ecr get-login --no-include-email --region $region

#upstart-job

host_name=$(hostname -s)
container_instance_id=${container_name}
avail_zone=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)

# Replace the cluster name and container instance ID placeholders with the actual values
sed -i -e "s/{container_instance_id}/$container_instance_id/g" /etc/awslogs/awslogs.conf
sed -i -e "s/{availzone}/$avail_zone/g" /etc/awslogs/awslogs.conf
sed -i -e "s/{hostname}/$host_name/g" /etc/awslogs/awslogs.conf

service awslogs start
chkconfig awslogs on
# end script


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