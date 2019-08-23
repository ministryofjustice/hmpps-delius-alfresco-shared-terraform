#!/bin/bash

JOB_TYPE=$1

if [ -z "${JOB_TYPE}" ]
then
    echo "JOB_TYPE argument not supplied."
    exit 1
fi

PREFIX_DATE=$(date +%F)

case ${JOB_TYPE} in
  db-backup)
    echo "Running db backup"
    BACKUP_DIR="/opt/local"
    SQL_FILE="${BACKUP_DIR}/alfresco.sql"

    # delete sql file from nfs share
    rm -rf ${BACKUP_DIR}/*.sql

    # Get passsword from ssm
    DB_USER=$(aws ssm get-parameters --region ${TG_REGION} --names "${ALF_DB_USERNAME_SSM}" --query "Parameters[0]"."Value" --output text) && echo Success || exit $?
    DB_PASSWORD=$(aws ssm get-parameters --with-decryption --region ${TG_REGION} --names "${ALF_DB_PASSWORD_SSM}" --query "Parameters[0]"."Value" --output text) && echo Success || exit $?
    
    # Perform db backup
    pg_dump --dbname=postgresql://${DB_USER}:${DB_PASSWORD}@${ALF_DB_HOST}:${DB_PORT}/${ALF_DB_NAME} -f ${SQL_FILE} && echo Success || exit $?

    # upload sql file
    aws s3 cp --only-show-errors ${SQL_FILE} s3://${ALF_BACKUP_BUCKET}/${PREFIX_DATE}/ && echo Success || exit $?

    # delete sql file from nfs share
    rm -rf ${SQL_FILE}

    ;;
  content-sync)
    echo "Running content sync"

    DAY_OF_WEEK=$(date +%u)

    # Perform content sync only on Fridays
    if [[ $DAY_OF_WEEK -eq 5 ]]
    then
      aws s3 sync s3://${ALF_STORAGE_BUCKET}/ s3://${ALF_BACKUP_BUCKET}/${PREFIX_DATE}/ && echo Success || exit $?
    else
      echo "Content sync step not completed - day of week is ${DAY_OF_WEEK}"
    fi
    ;;
  elasticsearch-backup)
    echo "Running elasticsearch backup"

    snapshot=${ES_SNAPSHOT_NAME}-${PREFIX_DATE}
    s3_repo_name="${ELK_S3_REPO_NAME}"
    s3_repo_bucket="${ELK_BACKUP_BUCKET}"

    echo "Creating repos"
    elasticsearch-manager addrepository ${s3_repo_name} --repo-type s3 --bucket ${s3_repo_bucket} && echo Success || exit $?

    sleep 30

    echo "Creating snapshot"
    elasticsearch-manager createsnapshot ${snapshot} --repository ${s3_repo_name} && echo Success || exit $?
    ;;
  *)
    echo "${JOB_TYPE} argument is not a valid argument. db-backup - content-sync"
  ;;
esac