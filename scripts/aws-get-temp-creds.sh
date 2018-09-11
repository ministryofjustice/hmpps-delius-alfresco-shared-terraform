#!/bin/bash

OUTPUT_FILE="env_configs/inspec-creds.properties"

temp_role=$(aws sts assume-role --role-arn ${TERRAGRUNT_IAM_ROLE} --role-session-name testing --duration-seconds 900)

echo "unset AWS_PROFILE
export AWS_ACCESS_KEY_ID=$(echo ${temp_role} | jq .Credentials.AccessKeyId | xargs)
export AWS_SECRET_ACCESS_KEY=$(echo ${temp_role} | jq .Credentials.SecretAccessKey | xargs)
export AWS_SESSION_TOKEN=$(echo ${temp_role} | jq .Credentials.SessionToken | xargs)" > ${OUTPUT_FILE}