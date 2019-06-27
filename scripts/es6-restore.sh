#!/bin/bash 

set +e

if [ -z "${ALF_RESTORE_STATUS}" ]
then
    ALF_RESTORE_STATUS="no-restore"
fi

repo_name="local"
snapshot=${ES_SNAPSHOT_NAME}
repo_path="/opt/local"
shared_repo_name="efs"
shared_repo_path="/opt/es_backup"
src_prefix="logstash-alfresco"
dst_prefix="alfresco-logstash"

echo "Waiting for elasticsearch..."
while ! nc -z ${ES_HOST} 9200; do
  sleep 0.1
done

echo "elasticsearch started on host: ${ES_HOST}"

if [ ${ALF_RESTORE_STATUS} = restore ]
then
  echo "Creating repos"
  elasticsearch-manager addrepository ${shared_repo_name} --path ${shared_repo_path} && echo Success || exit $?

  sleep 30

  echo "Running restore"
  elasticsearch-manager restore  ${shared_repo_name} --snapshot ${snapshot} --srcprefix ${dst_prefix} && echo Success || exit $?
else
  echo "Restore not completed"
fi

set -e