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

SYNC_COMMAND="s3://${CONFIG_BUCKET}/restore/elasticsearch/ ${repo_path}/"

echo "Waiting for elasticsearch..."
while ! nc -z ${ES_HOST} 9200; do
  sleep 0.1
done

if [ ${ALF_RESTORE_STATUS} = restore ]
then
  echo "--> syncing bucket ${CONFIG_BUCKET}"
  aws s3 sync --delete ${SYNC_COMMAND} && echo Success || exit $?

  chown -R elasticsearch:elasticsearch ${repo_path} && echo Success || exit $?
  echo "-> syncing complete"

  echo "elasticsearch started on host: ${ES_HOST}"

  echo "Creating repos"
  elasticsearch-manager addrepository ${repo_name} --repo-type fs --location ${repo_path} && echo Success || exit $?

  elasticsearch-manager addrepository ${shared_repo_name} --repo-type fs --location ${shared_repo_path} && echo Success || exit $?
  sleep 30

  echo "Running restore"
  elasticsearch-manager restore  ${repo_name} --snapshot ${snapshot} --srcprefix ${src_prefix} --reindex --dstprefix ${dst_prefix} && echo Success || exit $?

  sleep 10

  echo "Running create snapshot"
  elasticsearch-manager createsnapshot ${snapshot} --repository ${shared_repo_name} && echo Success || exit $?
else
  aws s3 sync --delete ${SYNC_COMMAND} --dryrun
fi
set -e