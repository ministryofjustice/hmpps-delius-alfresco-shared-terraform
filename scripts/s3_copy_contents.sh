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

TG_ENVIRONMENT_TYPE=$1
GIT_BRANCH=$2
REPO=${3}
REGION=${4}

echo "Output -> clone configs stage"
rm -rf ${env_config_dir}
echo "Output ---> Cloning branch: ${GIT_BRANCH}"
git clone -b ${GIT_BRANCH} ${REPO} ${env_config_dir}
echo "Output -> environment stage"

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

OUTPUT_FILE="env_configs/temp_creds"

temp_role=$(aws sts assume-role --role-arn ${TERRAGRUNT_IAM_ROLE} --role-session-name testing --duration-seconds 900)

echo "unset AWS_PROFILE
AWS_DEFAULT_REGION=${REGION}
export AWS_ACCESS_KEY_ID=$(echo ${temp_role} | jq .Credentials.AccessKeyId | xargs)
export AWS_SECRET_ACCESS_KEY=$(echo ${temp_role} | jq .Credentials.SecretAccessKey | xargs)
export AWS_SESSION_TOKEN=$(echo ${temp_role} | jq .Credentials.SessionToken | xargs)" > ${OUTPUT_FILE}

source ${OUTPUT_FILE}
rm -rf ${OUTPUT_FILE}

aws s3 sync s3://${SRC_S3_BUCKET}/TRN200/Alfresco/ s3://${DEST_S3_BUCKET} --dryrun