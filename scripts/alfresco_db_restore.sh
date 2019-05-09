#!/bin/sh

set -e

####VARS
DEST_BUCKET_PATH="restore_data"
ALFRESCO_SQL_FILE="alfresco.sql"

#Usage
# Scripts takes 2 arguments: environment_type and action
# environment_type: target environment example dev prod
# ACTION_TYPE: task to complete example plan apply test clean
# AWS_TOKEN: token to use when running locally eg hmpps-token

# Error handler function
exit_on_error() {
  exit_code=$1
  last_command=${@:2}
  if [ $exit_code -ne 0 ]; then
      >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
      exit ${exit_code}
  fi
}

env_config_dir="${HOME}/data/env_configs"

TG_ENVIRONMENT_TYPE=${1}

echo "Output -> clone configs stage"
rm -rf ${env_config_dir}
echo "Output ---> Cloning branch: master"
git clone https://github.com/ministryofjustice/hmpps-env-configs.git ${env_config_dir}
exit_on_error $? !!

echo "Output -> environment stage"

echo "Output -> environment_type set to: ${TG_ENVIRONMENT_TYPE}"

# setting Alfresco local properties
source ${HOME}/data/alf_env_configs/${TG_ENVIRONMENT_TYPE}.properties
exit_on_error $? !!

source ${env_config_dir}/${TG_ENVIRONMENT_TYPE}/${TG_ENVIRONMENT_TYPE}.properties
exit_on_error $? !!

echo "Output ---> set environment stage complete"

# source s3 bucket
#SRC_S3_BUCKET="${TG_ENVIRONMENT_IDENTIFIER}-backups-s3bucket"
SRC_S3_BUCKET="tf-alf-dev-elk-backups-s3bucket"

# dest s3 bucket
DEST_S3_BUCKET="${TG_ENVIRONMENT_IDENTIFIER}-alfresco-storage-s3bucket"

#Apply overides if character count is greater than 17
#To address names too long
if [ $(echo ${TG_ENVIRONMENT_TYPE} | wc -m) -ge 13 ]; then
    export TG_ENVIRONMENT_IDENTIFIER="tf-${TG_PROJECT_NAME_ABBREVIATED}"
    export TG_SHORT_ENVIRONMENT_IDENTIFIER="tf-${TG_PROJECT_NAME_ABBREVIATED}"
    export TG_SHORT_ENVIRONMENT_NAME="${TG_ENVIRONMENT_IDENTIFIER}"
    export TF_VAR_short_environment_identifier=${TG_SHORT_ENVIRONMENT_IDENTIFIER}
    export TF_VAR_environment_identifier=${TG_ENVIRONMENT_IDENTIFIER}
    export TF_VAR_short_environment_name=${TG_SHORT_ENVIRONMENT_NAME}
    DEST_S3_BUCKET="${TG_ENVIRONMENT_IDENTIFIER}-alfresco-storage-s3bucket"
fi

echo "Using IAM role: ${TERRAGRUNT_IAM_ROLE}"

export OUTPUT_FILE="env_configs/temp_creds"

export temp_role=$(aws sts assume-role --role-arn ${TERRAGRUNT_IAM_ROLE} --role-session-name testing --duration-seconds ${STS_DURATION})

# get creds
get_creds_aws () {
  sh scripts/get_creds.sh
  source ${OUTPUT_FILE}
  exit_on_error $? !!
  rm -rf ${OUTPUT_FILE}
  exit_on_error $? !!
}

get_creds_aws

echo "Run mode is: ${RUN_MODE}"

if [ ${RUN_MODE} = true ]
then
  echo "Run mode set to ${RUN_MODE}, no dry-run set"

  ##Copy alfresco.sql from backups bucket to storage s3bucket
  get_creds_aws
  aws s3 cp --only-show-errors s3://${SRC_S3_BUCKET}/${SRC_BUCKET_PATH}/${SRC_SQL_FILE} s3://${DEST_S3_BUCKET}/${DEST_BUCKET_PATH}/${ALFRESCO_SQL_FILE}
  exit_on_error $? !!
  echo "------> COPY of s3://${SRC_S3_BUCKET}/${SRC_BUCKET_PATH}/${SRC_SQL_FILE} to s3://${DEST_S3_BUCKET}/${DEST_BUCKET_PATH}/${ALFRESCO_SQL_FILE} DONE"

  ##Copy alfresco.sql from storage s3bucket to container
  get_creds_aws
  aws s3 cp --only-show-errors s3://${DEST_S3_BUCKET}/${DEST_BUCKET_PATH}/${ALFRESCO_SQL_FILE} ${ALFRESCO_SQL_FILE}
  exit_on_error $? !!
  echo "------> COPY of s3://${DEST_S3_BUCKET}/${DEST_BUCKET_PATH}/${ALFRESCO_SQL_FILE} to container DONE"



  #Prepare db before dataset restore
  echo "Commencing Alfresco DB restore"
  POSTGRES_ROLE="postgres"
  ALFRESCO_ROLE="alfresco"
  ALF_DB_USER=$(echo "alfresco${TG_ENVIRONMENT_TYPE}" | sed 's/-//')
  ALFRESCO_DB=${ALF_DB_USER}

  DB_IDENTIFIER="${TG_ENVIRONMENT_IDENTIFIER}-alfresco-rds"

  get_creds_aws
  RDS_DB_ENDPOINT=$(aws rds describe-db-instances --region ${TG_REGION} --db-instance-identifier ${DB_IDENTIFIER} \
				  --query 'DBInstances[*].[Endpoint]' | grep Address | awk '{print $2}' | sed 's/"//g')
  PARAM_STORE_NAME="${TG_ENVIRONMENT_IDENTIFIER}-alfresco-rds-db-password"


  echo "Dropping/Recreating DB and roles"
  get_creds_aws
  DB_PASSWORD=$(aws ssm get-parameters --with-decryption --names ${PARAM_STORE_NAME} --region ${TG_REGION} --query "Parameters[0]"."Value" | sed 's:^.\(.*\).$:\1:')

  psql postgresql://${ALF_DB_USER}:${DB_PASSWORD}@${RDS_DB_ENDPOINT}/postgres << EOF
      drop database ${ALFRESCO_DB};
      CREATE DATABASE ${ALFRESCO_DB};
      CREATE ROLE ${POSTGRES_ROLE};
      GRANT ${POSTGRES_ROLE} TO ${ALF_DB_USER};
      CREATE ROLE ${ALFRESCO_ROLE};
      GRANT ${ALFRESCO_ROLE} TO ${ALF_DB_USER};
EOF
  exit_on_error $? !!

  #Restore db from backup
 echo "Restoring ${ALFRESCO_SQL_FILE} to ${RDS_DB_ENDPOINT}"
 PGPASSWORD=${DB_PASSWORD} psql -h ${RDS_DB_ENDPOINT} -U ${ALF_DB_USER} -d ${ALFRESCO_DB} -f ${ALFRESCO_SQL_FILE}
 exit_on_error $? !!

else
  echo "Run mode set to ${RUN_MODE}, dry-run flags set"

  ##Copy alfresco.sql from backups bucket to storage s3bucket
  get_creds_aws
  aws s3 cp --only-show-errors s3://${SRC_S3_BUCKET}/${SRC_BUCKET_PATH}/${SRC_SQL_FILE} s3://${DEST_S3_BUCKET}/${DEST_BUCKET_PATH}/${ALFRESCO_SQL_FILE} --dryrun
  exit_on_error $? !!
  echo "------> COPY of s3://${SRC_S3_BUCKET}/${SRC_BUCKET_PATH}/${SRC_SQL_FILE} to s3://${DEST_S3_BUCKET}/${DEST_BUCKET_PATH}/${ALFRESCO_SQL_FILE} DONE"

  echo "DRY RUN COPY DONE"

  echo "2" > plan_ret
  exit_on_error $? !!
fi
