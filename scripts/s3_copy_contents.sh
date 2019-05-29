#!/bin/sh

set -e

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
SRC_S3_BUCKET="${TG_ENVIRONMENT_IDENTIFIER}-backups-s3bucket"

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
  get_creds_aws
  aws s3 rm s3://${DEST_S3_BUCKET} --recursive
  exit_on_error $? !!

  get_creds_aws
  aws s3 sync --only-show-errors s3://${SRC_S3_BUCKET}/${SRC_BUCKET_PATH}/contentstore s3://${DEST_S3_BUCKET}/contentstore
  exit_on_error $? !!

  get_creds_aws
  aws s3 sync --only-show-errors s3://${SRC_S3_BUCKET}/${SRC_BUCKET_PATH}/contentstore.deleted s3://${DEST_S3_BUCKET}/contentstore.deleted
  exit_on_error $? !!

  echo "------> SYNC DONE"

  ALFRESCO_SQL_FILE="alfresco.sql"

  get_creds_aws
  aws s3 cp s3://${SRC_S3_BUCKET}/${SRC_BUCKET_PATH}/${SRC_SQL_FILE} raw_${ALFRESCO_SQL_FILE}
  exit_on_error $? !!

  cat raw_${ALFRESCO_SQL_FILE} | grep -v '^(CREATE\ EXTENSION|COMMENT\ ON)' > ${ALFRESCO_SQL_FILE} 
  exit_on_error $? !!

  get_creds_aws
  aws s3 cp ${ALFRESCO_SQL_FILE} s3://${DEST_S3_BUCKET}/restore_data/${ALFRESCO_SQL_FILE}
  exit_on_error $? !!

  rm -rf *.sql
  exit_on_error $? !!
else
  echo "Run mode set to ${RUN_MODE}, dry-run flags set"
  get_creds_aws
  aws s3 rm s3://${DEST_S3_BUCKET} --recursive --dryrun
  exit_on_error $? !!

  get_creds_aws
  aws s3 sync s3://${SRC_S3_BUCKET}/${SRC_BUCKET_PATH}/contentstore s3://${DEST_S3_BUCKET}/contentstore --dryrun
  exit_on_error $? !!

  get_creds_aws
  aws s3 sync s3://${SRC_S3_BUCKET}/${SRC_BUCKET_PATH}/contentstore.deleted s3://${DEST_S3_BUCKET}/contentstore.deleted --dryrun
  exit_on_error $? !!

  echo "------> DRY RUN SYNC DONE"

  echo "2" > plan_ret
  exit_on_error $? !!
fi

## Remove extension creation commands from our sql file
# cat <pgdump_file> | grep -v -E '^(CREATE\ EXTENSION|COMMENT\ ON)' ><pg_dump_no_ext.sql