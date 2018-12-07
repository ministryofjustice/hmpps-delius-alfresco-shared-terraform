#!/bin/bash

Content-Type: multipart/mixed; boundary="==BOUNDARY=="
MIME-Version: 1.0

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash

# Set any ECS agent configuration options
cd /tmp

mkdir -p /etc/ecs
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config

# Install awslogs and the jq JSON parser
yum install -y awslogs jq

mkdir -p /var/log/${container_name}

# Inject the CloudWatch Logs configuration file contents
cat > /etc/awslogs/awslogs.conf <<- EOF
[general]
state_file = /var/lib/awslogs/agent-state

[application_log]
file = /var/log/${container_name}/*.log
log_group_name = ${environment_identifier}/${app_name}
log_stream_name = {availzone}/{cluster}/{hostname}/{container_instance_id}

[/var/log/dmesg]
file = /var/log/dmesg
log_group_name = ${environment_identifier}/dmesg_logs
log_stream_name = {availzone}/{cluster}/{hostname}/{container_instance_id}

[/var/log/messages]
file = /var/log/messages
log_group_name = ${environment_identifier}/messages_logs
log_stream_name = {availzone}/{cluster}/{hostname}/{container_instance_id}
datetime_format = %b %d %H:%M:%S

[/var/log/docker]
file = /var/log/docker
log_group_name = ${environment_identifier}/docker_logs
log_stream_name = {availzone}/{cluster}/{hostname}/{container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%S.%f

[/var/log/ecs/ecs-init.log]
file = /var/log/ecs/ecs-init.log.*
log_group_name = ${environment_identifier}/ecsinit_logs
log_stream_name = {availzone}/{cluster}/{hostname}/{container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ

[/var/log/ecs/ecs-agent.log]
file = /var/log/ecs/ecs-agent.log.*
log_group_name = ${environment_identifier}/ecsagent_logs
log_stream_name = {availzone}/{cluster}/{hostname}/{container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ

[/var/log/ecs/audit.log]
file = /var/log/ecs/audit.log.*
log_group_name = ${environment_identifier}/ecsaudit_logs
log_stream_name = {availzone}/{cluster}/{hostname}/{container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ
EOF

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
# Set the region to send CloudWatch Logs data to (the region where the container instance is located)
region=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
sed -i -e "s/region = us-east-1/region = $region/g" /etc/awslogs/awscli.conf

# log into AWS ECR
`aws ecr get-login --no-include-email --region $region`

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
#!/usr/bin/env bash

yum install -y git
easy_install pip

cat << EOF >> /etc/environment
HMPPS_ROLE=${app_name}
HMPPS_FQDN="`curl http://169.254.169.254/latest/meta-data/instance-id`.${private_domain}"
HMPPS_STACKNAME=${env_identifier}
HMPPS_STACK="${short_env_identifier}"
HMPPS_ENVIRONMENT=${route53_sub_domain}
HMPPS_ACCOUNT_ID="${account_id}"
HMPPS_DOMAIN="${private_domain}"
EOF
## Ansible runs in the same shell that has just set the env vars for future logins so it has no knowledge of the vars we've
## just configured, so lets export them
export HMPPS_ROLE="${app_name}"
export HMPPS_FQDN="`curl http://169.254.169.254/latest/meta-data/instance-id`.${private_domain}"
export HMPPS_STACKNAME="${env_identifier}"
export HMPPS_STACK="${short_env_identifier}"
export HMPPS_ENVIRONMENT=${route53_sub_domain}
export HMPPS_ACCOUNT_ID="${account_id}"
export HMPPS_DOMAIN="${private_domain}"

cd ~
/usr/local/bin/pip install ansible awscli

cat << EOF > ~/requirements.yml
- name: bootstrap
  src: https://github.com/ministryofjustice/hmpps-bootstrap
  version: amazonlinux
- name: rsyslog
  src: https://github.com/ministryofjustice/hmpps-rsyslog-role
- name: elasticbeats
  src: https://github.com/ministryofjustice/hmpps-beats-monitoring
EOF

cat << EOF > ~/bootstrap.yml
---

- hosts: localhost
  roles:
     - bootstrap
     - rsyslog
     - elasticbeats

EOF

/usr/local/bin/ansible-galaxy install -f -r ~/requirements.yml
HAS_DOCKER=True /usr/local/bin/ansible-playbook ~/bootstrap.yml -e mount_point="${keys_dir}" -e device_name="${ebs_device}" -e monitoring_host="${monitoring_server_url}"

#Self register our instance url, we'll need a script to clean up after ourselves, this can be moved to an ansible play as well
cat << EOT >> /self_register.json
{
    "Comment": "ecs node dns self registration",
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "#INSTANCE_FQDN#",
                "Type": "A",
                "TTL": 300,
                "ResourceRecords": [
                    {
                        "Value": "#INSTANCE_IP#"
                    }
                ]
            }
        }
    ]
}
EOT
cat /self_register.json | sed -e "s/\#INSTANCE_IP\#/$(curl http://169.254.169.254/latest/meta-data/local-ipv4)/"  > /self_register.json
cat /self_register.json | sed -e "s/\#INSTANCE_FQDN\#/$(curl http://169.254.169.254/latest/meta-data/instance-id).${private_domain}/"  > /self_register.json
aws route53 change-resource-record-sets --hosted-zone-id `aws route53 list-hosted-zones | grep \"${private_domain}.\" -B1 | grep -v \"${private_domain}.\" | cut -d'/' -f3 | sed -e 's/",//'` --change-batch=file:///self_register.json


# #Get our license
# mkdir -p /srv/license/
# aws s3 cp s3://tf-eu-west-2-hmpps-alf-dev-config-s3bucket/alfresco/Alfresco-ent51-NOMS.lic /srv/license/Alfresco-ent51-NOMS.lic
# chown -R  1000:1000 /srv/license

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
cluster=$(curl -s http://localhost:51678/v1/metadata | jq -r '. | .Cluster')
container_instance_id=${container_name}
avail_zone=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)

# Replace the cluster name and container instance ID placeholders with the actual values
sed -i -e "s/{cluster}/$cluster/g" /etc/awslogs/awslogs.conf
sed -i -e "s/{container_instance_id}/$container_instance_id/g" /etc/awslogs/awslogs.conf
sed -i -e "s/{availzone}/$avail_zone/g" /etc/awslogs/awslogs.conf

service awslogs start
chkconfig awslogs on
end script


