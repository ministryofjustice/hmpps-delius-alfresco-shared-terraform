#!/bin/bash
# Get passsword from ssm
DB_USER=$(aws ssm get-parameters --region ${TG_REGION} --names "${ALF_DB_USERNAME_SSM}" --query "Parameters[0]"."Value" --output text) && echo Success || exit $?
DB_PASSWORD=$(aws ssm get-parameters --with-decryption --region ${TG_REGION} --names "${ALF_DB_PASSWORD_SSM}" --query "Parameters[0]"."Value" --output text) && echo Success || exit $?

echo "Running Postgres update for stats on alf_node_aspects and alf_node_properties"
psql postgresql://${DB_USER}:${DB_PASSWORD}@${ALF_DB_HOST}/${ALF_DB_NAME} << EOF
  alter table alf_node_aspects alter qname_id SET STATISTICS 2000;
  alter table alf_node_properties alter node_id SET STATISTICS 2000;
EOF
