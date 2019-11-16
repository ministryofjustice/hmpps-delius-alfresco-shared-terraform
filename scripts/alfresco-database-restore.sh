#!/bin/bash 

set +e

# Error handler function
exit_on_error() {
  exit_code=$1
  last_command=${@:2}
  if [ $exit_code -ne 0 ]; then
      >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
      exit ${exit_code}
  fi
}

if [ -z "${ALF_RESTORE_STATUS}" ]
then
    ALF_RESTORE_STATUS="no-restore"
fi

aws configure set default.s3.max_concurrent_requests 500

perform_db_restore ()
{
  echo "Run mode is: ${ALF_RESTORE_STATUS}"
  DUMP_DIR="/opt/local"
  mkdir -p ${DUMP_DIR}
  exit_on_error $? !!

  if [ ${ALF_RESTORE_STATUS} = restore ]
  then
    echo "Run mode set to ${ALF_RESTORE_STATUS}, will perform database restore"

    # Download only sql file, assumes only one file found
    aws s3 sync  s3://${CONFIG_BUCKET}/restore/db_temp/ ${DUMP_DIR}/
    exit_on_error $? !!
    echo "SQL file sync done"
    
    echo "Commencing Alfresco DB restore"
    POSTGRES_ROLE="postgres"
    ALFRESCO_ROLE="alfresco"

    # Get passsword from ssm
    DB_USER=$(aws ssm get-parameters --region ${TG_REGION} --names "${ALF_DB_USERNAME_SSM}" --query "Parameters[0]"."Value" --output text)
    DB_PASSWORD=$(aws ssm get-parameters --with-decryption --region ${TG_REGION} --names "${ALF_DB_PASSWORD_SSM}" --query "Parameters[0]"."Value" --output text)
    exit_on_error $? !!
    psql postgresql://${DB_USER}:${DB_PASSWORD}@${ALF_DB_HOST}/postgres << EOF
        drop database ${ALF_DB_NAME};
        CREATE DATABASE ${ALF_DB_NAME};
        CREATE ROLE ${POSTGRES_ROLE};
        GRANT ${POSTGRES_ROLE} TO ${DB_USER};
        CREATE ROLE ${ALFRESCO_ROLE};
        GRANT ${ALFRESCO_ROLE} TO ${DB_USER};
EOF
    exit_on_error $? !!
    #Restore db from backup
    echo "Restoring ${ALFRESCO_SQL_FILE} to ${ALF_DB_HOST}"
    # PGPASSWORD=${DB_PASSWORD} psql -h ${ALF_DB_HOST} -U ${DB_USER} -d ${ALF_DB_NAME} -f ${ALFRESCO_SQL_FILE}
    pg_restore --clean --jobs=4 --format=d --dbname=postgresql://${DB_USER}:${DB_PASSWORD}@${ALF_DB_HOST}:${DB_PORT}/${ALF_DB_NAME} ${DUMP_DIR}
    exit_on_error $? !!
    echo "db restore completed"
    rm -rf ${DUMP_DIR}
  else
    echo "Run mode set to ${ALF_RESTORE_STATUS}, dry-run flags set"

    ##Copy alfresco.sql from backups bucket to storage s3bucket
    
    aws s3 sync --dryrun s3://${CONFIG_BUCKET}/restore/db/ ${DUMP_DIR}/
    echo "DRY RUN COPY DONE"
  fi
}

perform_db_restore

set -e
