#!/bin/bash

JOB_TYPE=$1

if [ -z "${JOB_TYPE}" ]
then
    echo "JOB_TYPE argument not supplied."
    exit 1
fi

PREFIX_DATE=$(date +%F)
aws configure set default.s3.max_concurrent_requests 250

case ${JOB_TYPE} in
  elasticsearch-backup)
    echo "Running elasticsearch backup"
    export DAILY_SNAPSHOT_NAME="${ES_SNAPSHOT_NAME}-$(date '+%Y-%-m-%-d')"

    echo "Clearing backup bucket"
    aws s3 rm --recursive --only-show-errors s3://${ELK_BACKUP_BUCKET}/

    # echo "Creating repos"
    # elasticsearch-manager addrepository ${ELK_S3_REPO_NAME} --repo-type s3 --bucket ${ELK_BACKUP_BUCKET} && echo Success || exit $?

    # sleep 30

    echo "Creating snapshot"
    curator --config /opt/scripts/curator/config.yml /opt/scripts/curator/es-migration.yml && echo Success || exit $??
    ;;
  *)
    echo "${JOB_TYPE} argument is not a valid argument. db-backup - content-sync - elasticsearch-backup"
  ;;
esac
