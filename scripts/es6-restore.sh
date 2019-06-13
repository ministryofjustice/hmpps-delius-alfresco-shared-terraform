#!/bin/bash 

set +e

source /opt/scripts/common.properties

echo "Waiting for elasticsearch..."
while ! nc -z ${ES_HOST} 9200; do
  sleep 0.1
done

echo "elasticsearch started on host: ${ES_HOST}"

echo "Creating repos"
elasticsearch-manager addrepository ${shared_repo_name} --path ${shared_repo_path}

sleep 30

echo "Running restore"
elasticsearch-manager restore  ${shared_repo_name} --snapshot ${snapshot} --srcprefix ${dst_prefix}

set -e