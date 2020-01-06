#!/bin/bash

JOB_TYPE=$1

if [ -z "${JOB_TYPE}" ]
then
    echo "JOB_TYPE argument not supplied."
    exit 1
fi

# Get passsword from ssm
DB_USER=$(aws ssm get-parameters --region ${TG_REGION} --names "${ALF_DB_USERNAME_SSM}" --query "Parameters[0]"."Value" --output text) && echo Success || exit $?
DB_PASSWORD=$(aws ssm get-parameters --with-decryption --region ${TG_REGION} --names "${ALF_DB_PASSWORD_SSM}" --query "Parameters[0]"."Value" --output text) && echo Success || exit $?

case ${JOB_TYPE} in
  vacuum-tables)
    echo "Running Postgres DB table analyze Vacuum for alf_node alf_node_properties and alf_node_aspect"
    psql postgresql://${DB_USER}:${DB_PASSWORD}@${ALF_DB_HOST}/${ALF_DB_NAME} << EOF
VACUUM(ANALYZE, VERBOSE) alf_node_aspects;
VACUUM(ANALYZE, VERBOSE) alf_node_properties;
VACUUM(ANALYZE, VERBOSE) alf_node;
EOF
    ;;
  *)
    echo "${JOB_TYPE} argument is not a valid argument. db-backup - content-sync - elasticsearch-backup"
  ;;
esac
