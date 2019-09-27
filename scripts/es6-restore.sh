#!/bin/bash 

set +e

if [ -z "${ALF_RESTORE_STATUS}" ]
then
    ALF_RESTORE_STATUS="no-restore"
fi

snapshot="migrated-${ES_SNAPSHOT_NAME}"
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

SCRIPT_DIR="/opt/scripts"
CURATOR_FILES_DIR="${SCRIPT_DIR}/curator"

if [ ${ALF_RESTORE_STATUS} = restore ]
then
  echo "Creating repos"
  python ${SCRIPT_DIR}/create_s3_local_repo.py && echo Success || exit $?

  echo "Running curator"
  curator --config ${CURATOR_FILES_DIR}/config.yml ${CURATOR_FILES_DIR}/action_migration-es6.yml && echo Success || exit $?
  # checking cluster is green
  python ${SCRIPT_DIR}/check_cluster_health.py && echo Success || exit $?
else
  echo "Restore not completed"
fi

set -e
