#!/bin/bash 

set +e

repo_name="local"
snapshot="snapshot_1"
repo_path="/opt/local"
shared_repo_name="efs"
shared_repo_path="/opt/es_backup"
src_prefix="alfresco-logstash"

echo "Waiting for elasticsearch..."
while ! nc -z ${ES_HOST} 9200; do
  sleep 0.1
done

echo "elasticsearch started on host: ${ES_HOST}"

echo "Creating repos"
elasticsearch-manager addrepository ${shared_repo_name} --path ${shared_repo_path}

sleep 30

echo "Running restore"
elasticsearch-manager restore  ${shared_repo_name} --snapshot ${snapshot} --srcprefix ${src_prefix}

set -e