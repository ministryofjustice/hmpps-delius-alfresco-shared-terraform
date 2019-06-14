#!/bin/bash 
set +e

repo_name="local"
snapshot="snapshot_1"
repo_path="/opt/local"
shared_repo_name="efs"
shared_repo_path="/opt/es_backup"
src_prefix="logstash-alfresco"
dst_prefix="alfresco-logstash"

echo "--> syncing bucket ${CONFIG_BUCKET}"
aws s3 sync s3://${CONFIG_BUCKET}/elasticsearch/ ${repo_path}/

chown -R elasticsearch:elasticsearch ${repo_path}
echo "-> syncing complete"

echo "Waiting for elasticsearch..."
while ! nc -z ${ES_HOST} 9200; do
  sleep 0.1
done

echo "elasticsearch started on host: ${ES_HOST}"

echo "Creating repos"
elasticsearch-manager addrepository ${repo_name} --path ${repo_path}

elasticsearch-manager addrepository ${shared_repo_name} --path ${shared_repo_path}

sleep 30

echo "Running restore"
elasticsearch-manager restore  ${repo_name} --snapshot ${snapshot} --srcprefix ${src_prefix} --reindex --dstprefix ${dst_prefix}

sleep 10

echo "Running create snapshot"
elasticsearch-manager createsnapshot ${snapshot} --repository ${shared_repo_name}

set -e