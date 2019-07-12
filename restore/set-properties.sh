#!/bin/sh 
# Error handler function
set +e
exit_on_error() {
  exit_code=$1
  last_command=${@:2}
  if [ $exit_code -ne 0 ]; then
      >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
      exit ${exit_code}
  fi
}

TARGET_ENV=$1
DOCKER_CERTS_DIR=$2


if [ -z "${TARGET_ENV}" ]
then
    echo "environment argument not supplied, please provide an argument!"
    exit 1
fi

if [ -z "${DOCKER_CERTS_DIR}" ]
then
    echo "certs dir argument not supplied, please provide an argument!"
    exit 1
fi

docker_tls_dir=${DOCKER_CERTS_DIR}
docker_key_file=$docker_tls_dir/key.pem
docker_cert_file=$docker_tls_dir/cert.pem
docker_ca_cert_file=$docker_tls_dir/ca.pem
outfile=$docker_tls_dir/temp_creds
outfile_docker=$docker_tls_dir/docker.properties
tf_data=$docker_tls_dir/tf_output

sudo rm -rf $docker_tls_dir
exit_on_error $? !!
sudo mkdir -p $docker_tls_dir
exit_on_error $? !!

sudo touch $outfile $docker_key_file $docker_ca_cert_file $docker_cert_file tf_data $outfile_docker
exit_on_error $? !!

sudo chown -R centos:centos $docker_tls_dir
exit_on_error $? !!
sudo chmod -R 770 $docker_tls_dir
exit_on_error $? !!

# get outputs es_admin node
comp=es_admin
python docker-run.py --env ${TARGET_ENV} --component $comp --action output > $tf_data

# Blank out docker props file
echo '#/bin/bash' > $outfile_docker

# set docker host
export ES_DOCKER_HOST=$(cat $tf_data | grep es_admin_host | cut -d ' ' -f3)
echo "export ES_DOCKER_HOST=${ES_DOCKER_HOST}" >> $outfile_docker
exit_on_error $? !!

export CONFIG_BUCKET=$(cat $tf_data | grep config_bucket | cut -d ' ' -f3)
echo "export CONFIG_BUCKET=${CONFIG_BUCKET}" >> $outfile_docker
exit_on_error $? !!


export ES_LB_DNS=$(cat $tf_data | grep elk_lb_dns | cut -d ' ' -f3)
echo "export ES_LB_DNS=${ES_LB_DNS}" >> $outfile_docker
exit_on_error $? !!


export ES_SNAPSHOT_NAME=$(cat $tf_data | grep es_snapshot_name | cut -d ' ' -f3)
echo "export ES_SNAPSHOT_NAME=${ES_SNAPSHOT_NAME}" >> $outfile_docker
exit_on_error $? !!

export ALF_ASG_PREFIX=$(cat $tf_data | grep asg_prefix | cut -d ' ' -f3)
echo "export ALF_ASG_PREFIX=${ALF_ASG_PREFIX}" >> $outfile_docker
exit_on_error $? !!

export ES_DYNAMODB_TABLE_NAME=$(cat $tf_data | grep dynamodb_table_name | cut -d ' ' -f3)
echo "export ES_DYNAMODB_TABLE_NAME=${ES_DYNAMODB_TABLE_NAME}" >> $outfile_docker
exit_on_error $? !!

export ALF_STORAGE_BUCKET=$(cat $tf_data | grep storage_s3bucket | cut -d ' ' -f3)
echo "export ALF_STORAGE_BUCKET=${ALF_STORAGE_BUCKET}" >> $outfile_docker
exit_on_error $? !!

export ALF_RESTORE_STATUS=$(cat $tf_data | grep alf_restore_status | cut -d ' ' -f3)
echo "export ALF_RESTORE_STATUS=${ALF_RESTORE_STATUS}" >> $outfile_docker
exit_on_error $? !!

# RDS
export ALF_DB_HOST=$(cat $tf_data | grep alf_db_host | cut -d ' ' -f3)
echo "export ALF_DB_HOST=${ALF_DB_HOST}" >> $outfile_docker
exit_on_error $? !!

export ALF_DB_NAME=$(cat $tf_data | grep alf_db_name | cut -d ' ' -f3)
echo "export ALF_DB_NAME=${ALF_DB_NAME}" >> $outfile_docker
exit_on_error $? !!

export ALF_DB_PASSWORD_SSM=$(cat $tf_data | grep alf_db_password_ssm | cut -d ' ' -f3)
echo "export ALF_DB_PASSWORD_SSM=${ALF_DB_PASSWORD_SSM}" >> $outfile_docker
exit_on_error $? !!

export ALF_DB_USERNAME_SSM=$(cat $tf_data | grep alf_db_username_ssm | cut -d ' ' -f3)
echo "export ALF_DB_USERNAME_SSM=${ALF_DB_USERNAME_SSM}" >> $outfile_docker
exit_on_error $? !!

# AWS
echo "export TERRAGRUNT_IAM_ROLE=$(cat $tf_data | grep terragrunt_iam_role | cut -d ' ' -f3)" >> $outfile_docker
exit_on_error $? !!

echo "export TG_REGION=$(cat $tf_data | grep region | cut -d ' ' -f3)" >> $outfile_docker
exit_on_error $? !!

##################################################################################################
# get cert details
comp=certs
python docker-run.py --env ${TARGET_ENV} --component $comp --action output > $tf_data

eval $(cat env_configs/${TARGET_ENV}/${TARGET_ENV}.properties | grep TERRAGRUNT_IAM_ROLE)
exit_on_error $? !!
eval $(cat env_configs/${TARGET_ENV}/${TARGET_ENV}.properties | grep TG_REGION)
exit_on_error $? !!

# get temp creds
export temp_role=$(aws sts assume-role --role-arn ${TERRAGRUNT_IAM_ROLE} --role-session-name ci --duration-seconds 900)
exit_on_error $? !!

echo "unset AWS_PROFILE
AWS_DEFAULT_REGION=${TG_REGION}
export AWS_ACCESS_KEY_ID=$(echo ${temp_role} | jq .Credentials.AccessKeyId | xargs)
export AWS_SECRET_ACCESS_KEY=$(echo ${temp_role} | jq .Credentials.SecretAccessKey | xargs)
export AWS_SESSION_TOKEN=$(echo ${temp_role} | jq .Credentials.SessionToken | xargs)" > ${outfile}
exit_on_error $? !!

source $outfile
exit_on_error $? !!

echo "export TEMP_CREDS_FILE=$outfile" >> $outfile_docker

export ssm_ca_cert=$(cat $tf_data | grep self_signed_ca_ssm_cert_pem_name | cut -d ' ' -f3)
export ssm_cert=$(cat $tf_data | grep  self_signed_server_ssm_cert_pem_name | cut -d ' ' -f3)
export ssm_private_key=$(cat $tf_data | grep  self_signed_server_ssm_private_key_name| cut -d ' ' -f3)

# Get SSM certs
aws ssm get-parameters --with-decryption --names $ssm_private_key --region ${TG_REGION} --query "Parameters[0]"."Value" --output text > $docker_key_file
exit_on_error $? !!
aws ssm get-parameters --names $ssm_ca_cert --region ${TG_REGION} --query "Parameters[0]"."Value" --output text > $docker_ca_cert_file
exit_on_error $? !!
aws ssm get-parameters --names $ssm_cert --region ${TG_REGION} --query "Parameters[0]"."Value" --output text > $docker_cert_file
exit_on_error $? !!

# sync scripts dir
echo "syncing files"
aws s3 sync ./scripts s3://${CONFIG_BUCKET}/scripts/
exit_on_error $? !!

##################################################################################################

export DOCKER_PORT=2376
echo "export DOCKER_PORT=${DOCKER_PORT}" >> $outfile_docker

export DOCKER_HOST=tcp://${ES_DOCKER_HOST}:$DOCKER_PORT
echo "export DOCKER_HOST=${DOCKER_HOST}" >> $outfile_docker

export DOCKER_TLS_VERIFY=1
echo "export DOCKER_TLS_VERIFY=${DOCKER_TLS_VERIFY}" >> $outfile_docker

export DOCKER_CERT_PATH=${docker_tls_dir}
echo "export DOCKER_CERT_PATH=${DOCKER_CERT_PATH}" >> $outfile_docker

# script will loop for 7.5 mins (15x30) 
echo "Checking docker host is up..."
int=1
sleep_period=0.1
while ! nc -z ${ES_DOCKER_HOST} $DOCKER_PORT; do
  sleep $sleep_period
  echo "waiting for connection..."
  int=$(($int+1))
  if (($int > 15))
  then 
    echo "Connection to docker host timeout"
    exit 1
  fi
  sleep_period=30
done
echo "Docker host is up ${ES_DOCKER_HOST}"
docker-compose -f restore/docker-compose-sync-scripts.yml up
exit_on_error $? !!
set -e