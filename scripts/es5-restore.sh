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
src_prefix="logstash"
dst_prefix="alfresco-logstash"


# echo "Waiting for elasticsearch..."
# while ! nc -z ${ES_HOST} 9200; do
#   sleep 0.1
# done

echo "elasticsearch started on host: ${ES_HOST}"

export SCRIPT_DIR="/opt/scripts"
export CURATOR_FILES_DIR="${SCRIPT_DIR}/curator"

if [ ${ALF_RESTORE_STATUS} = restore ]
then
  echo "Creating repos"
  python ${SCRIPT_DIR}/create_s3_local_repo.py && echo Success || exit $?

  echo "Running curator close indices"
  curator --config ${CURATOR_FILES_DIR}/config.yml ${CURATOR_FILES_DIR}/action_close.yml && echo Success || exit $?

  echo "Running curator restore"
  curator --config ${CURATOR_FILES_DIR}/config.yml ${CURATOR_FILES_DIR}/action_migration.yml && echo Success || exit $?
  # checking cluster is green
  python ${SCRIPT_DIR}/check_cluster_health.py && echo Success || exit $?

  echo "Running curator open indices"
  curator --config ${CURATOR_FILES_DIR}/config.yml ${CURATOR_FILES_DIR}/action_open.yml && echo Success || exit $?
  echo "done"
  
  # reindex indices
  # echo "Running curator reindex"
  # export REINDEX_SHELL_SCRIPT="reindex_indices.sh" 
  # rm -rf ${SCRIPT_DIR}/${REINDEX_SHELL_SCRIPT}
  # python ${SCRIPT_DIR}/reindex.py && echo Success || exit $?
  # sh ${SCRIPT_DIR}/${REINDEX_SHELL_SCRIPT} && echo Success || exit $? 
  # echo "done"

  echo "Running create snapshot"
  curator --config ${CURATOR_FILES_DIR}/config.yml ${CURATOR_FILES_DIR}/action_migration_snapshot.yml && echo Success || exit $?
  echo "done"
else
  echo "Restore not complete"
fi
set -e
