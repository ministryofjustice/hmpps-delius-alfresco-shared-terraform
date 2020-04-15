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
  db-backup)
    echo "Running db backup $(date)"
    BACKUP_DIR="/opt/local"
    DUMP_DIR="${BACKUP_DIR}/alfresco_dump"

    # delete sql file from nfs share
    rm -rf ${DUMP_DIR}

    # Get passsword from ssm
    DB_USER=$(aws ssm get-parameters --region ${TG_REGION} --names "${ALF_DB_USERNAME_SSM}" --query "Parameters[0]"."Value" --output text) && echo Success || exit $?
    DB_PASSWORD=$(aws ssm get-parameters --with-decryption --region ${TG_REGION} --names "${ALF_DB_PASSWORD_SSM}" --query "Parameters[0]"."Value" --output text) && echo Success || exit $?
    
    # Perform db backup
    echo "DB host: ${ALF_DB_HOST}"
    pg_dump --jobs=4 --format=d -f ${DUMP_DIR} --dbname=postgresql://${DB_USER}:${DB_PASSWORD}@${ALF_DB_HOST}:${DB_PORT}/${ALF_DB_NAME} && echo Success || exit $?
    echo "Completed db backup $(date)"

    # upload sql file
    echo "uploading postgres pg_dump $(date)"
    aws s3 sync --only-show-errors ${DUMP_DIR}/ s3://${ALF_BACKUP_BUCKET}/database/${PREFIX_DATE}/ && echo Success || exit $?
    echo "uploading postgres pg_dump complete $(date)"

    # delete sql file from nfs share
    rm -rf ${DUMP_DIR}

    ;;
  content-sync)
    echo "Running content sync"

    # Perform content sync previous day
    BASE_DIR="$(date '+%Y/%-m/%-1d')"
    FOLDER_TO_SYNC="contentstore/${BASE_DIR}"
    echo "Running command: aws s3 sync --only-show-errors s3://${ALF_STORAGE_BUCKET}/${FOLDER_TO_SYNC}/ s3://${ALF_BACKUP_BUCKET}/files/${FOLDER_TO_SYNC}/"
    aws s3 sync --only-show-errors s3://${ALF_STORAGE_BUCKET}/${FOLDER_TO_SYNC}/ s3://${ALF_BACKUP_BUCKET}/files/${FOLDER_TO_SYNC}/ && echo Success || exit $?
    echo "Running command: aws s3 sync --only-show-errors s3://${ALF_STORAGE_BUCKET}/${BASE_DIR}/ s3://${ALF_BACKUP_BUCKET}/files/${BASE_DIR}/"
    aws s3 sync --only-show-errors s3://${ALF_STORAGE_BUCKET}/${BASE_DIR}/ s3://${ALF_BACKUP_BUCKET}/files/${BASE_DIR}/ && echo Success || exit $?

    # Perform content sync daily
    BASE_DIR="$(date '+%Y/%-m/%-d')"
    FOLDER_TO_SYNC="contentstore/${BASE_DIR}"
    echo "Running command: aws s3 sync --only-show-errors s3://${ALF_STORAGE_BUCKET}/${FOLDER_TO_SYNC}/ s3://${ALF_BACKUP_BUCKET}/files/${FOLDER_TO_SYNC}/"
    aws s3 sync --only-show-errors s3://${ALF_STORAGE_BUCKET}/${FOLDER_TO_SYNC}/ s3://${ALF_BACKUP_BUCKET}/files/${FOLDER_TO_SYNC}/ && echo Success || exit $?
    echo "Running command: aws s3 sync --only-show-errors s3://${ALF_STORAGE_BUCKET}/${BASE_DIR}/ s3://${ALF_BACKUP_BUCKET}/files/${BASE_DIR}/"
    aws s3 sync --only-show-errors s3://${ALF_STORAGE_BUCKET}/${BASE_DIR}/ s3://${ALF_BACKUP_BUCKET}/files/${BASE_DIR}/ && echo Success || exit $?

    ;;
  elasticsearch-backup)
    echo "Running elasticsearch backup"
    export DAILY_SNAPSHOT_NAME="${ES_SNAPSHOT_NAME}-$(date '+%Y-%-m-%-d')"

    echo "Clearing backup bucket"
    aws s3 rm --recursive --only-show-errors s3://${ELK_BACKUP_BUCKET}/

    echo "Creating repos"
    elasticsearch-manager addrepository ${ELK_S3_REPO_NAME} --repo-type s3 --bucket ${ELK_BACKUP_BUCKET} && echo Success || exit $?

    sleep 30

    echo "Creating snapshot"
    curator --config /opt/scripts/curator/config.yml /opt/scripts/curator/action_daily_snapshot.yml && echo Success || exit $?
    # SYNC to backup bucket
    aws s3 sync --only-show-errors s3://${ELK_BACKUP_BUCKET}/ s3://${ALF_BACKUP_BUCKET}/elasticsearch/$(date '+%Y/%-m/%-d')/ && echo Success || exit $?

    echo "Running elasticsearch purge"
    PURGE_ACTION_FILE="/opt/scripts/curator/action_purge.yml"
    INDICES_DAYS=${DAYS_TO_DELETE}
    echo "DAYS_TO_DELETE set to ${INDICES_DAYS}"
    sed -i "s/DELETE_DAYS/${INDICES_DAYS}/g" ${PURGE_ACTION_FILE}
    cat ${PURGE_ACTION_FILE}

    echo "Purging old indices"
    curator --config /opt/scripts/curator/config.yml ${PURGE_ACTION_FILE} && echo Success || exit $?
    ;;
  *)
    echo "${JOB_TYPE} argument is not a valid argument. db-backup - content-sync - elasticsearch-backup"
  ;;
esac
