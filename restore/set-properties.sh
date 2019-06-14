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

export INTERNAL_DOMAIN=$(cat $tf_data | grep internal_domain | cut -d ' ' -f3)
echo "export INTERNAL_DOMAIN=${INTERNAL_DOMAIN}" >> $outfile_docker
exit_on_error $? !!

export ES_LB_DNS=$(cat $tf_data | grep elk_lb_dns | cut -d ' ' -f3)
echo "export ES_LB_DNS=${ES_LB_DNS}" >> $outfile_docker
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
set -e