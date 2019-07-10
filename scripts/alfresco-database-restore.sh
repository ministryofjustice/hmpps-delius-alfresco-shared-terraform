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



perform_db_restore ()
{
  echo "Run mode is: ${ALF_RESTORE_STATUS}"
  temp_database_files="/tmp/restore"
  mkdir -p ${temp_database_files}
  exit_on_error $? !!

  if [ ${ALF_RESTORE_STATUS} = restore ]
  then
    echo "Run mode set to ${ALF_RESTORE_STATUS}, will perform database restore"

    # Download only sql file, assumes only one file found
    aws s3 cp s3://${CONFIG_BUCKET}/restore/ ${temp_database_files}/ --recursive --exclude "*" --include "*.sql"
    exit_on_error $? !!

    # db file to restore, assumes only one file found
    ALFRESCO_SQL_FILE=$(find ${temp_database_files} -type f -name alfresco_*.sql)
    exit_on_error $? !!

    #Comment out below lines causing error on data restore
    if [[ -f ${ALFRESCO_SQL_FILE} ]] ; then
        sed -i 's/COMMENT ON EXTENSION plpgsql/-- COMMENT ON EXTENSION plpgsql/' ${ALFRESCO_SQL_FILE}
        exit_on_error $? !!
    fi
    #Prepare db before dataset restore
    echo "Commencing Alfresco DB restore"
    POSTGRES_ROLE="postgres"
    ALFRESCO_ROLE="alfresco"
    ALFRESCO_DB=${ALF_DB_NAME}
    RDS_DB_ENDPOINT=${ALF_DB_HOST}

    # Get passsword from ssm
    DB_USER=$(aws ssm get-parameters --region ${TG_REGION} --names "${ALF_DB_USERNAME_SSM}" --query "Parameters[0]"."Value" --output text)
    DB_PASSWORD=$(aws ssm get-parameters --with-decryption --region ${TG_REGION} --names "${ALF_DB_PASSWORD_SSM}" --query "Parameters[0]"."Value" --output text)
    exit_on_error $? !!
    psql postgresql://${DB_USER}:${DB_PASSWORD}@${RDS_DB_ENDPOINT}/postgres << EOF
        drop database ${ALFRESCO_DB};
        CREATE DATABASE ${ALFRESCO_DB};
        CREATE ROLE ${POSTGRES_ROLE};
        GRANT ${POSTGRES_ROLE} TO ${DB_USER};
        CREATE ROLE ${ALFRESCO_ROLE};
        GRANT ${ALFRESCO_ROLE} TO ${DB_USER};
EOF
    exit_on_error $? !!
  else
    echo "Run mode set to ${ALF_RESTORE_STATUS}, dry-run flags set"

    ##Copy alfresco.sql from backups bucket to storage s3bucket
    
    aws s3 cp s3://${CONFIG_BUCKET}/restore/ ${temp_database_files}/ --recursive --exclude "*" --include "*.sql" --dryrun
    echo "DRY RUN COPY DONE"
  fi
}

perform_db_restore

set -e