#!/bin/sh 
set +e

docker_key_file=${DOCKER_CERTS_DIR}/key.pem
docker_cert_file=${DOCKER_CERTS_DIR}/cert.pem
docker_ca_cert_file=${DOCKER_CERTS_DIR}/ca.pem
outfile=${DOCKER_CERTS_DIR}/temp_creds
outfile_docker=${DOCKER_CERTS_DIR}/docker.properties
tf_data=${DOCKER_CERTS_DIR}/tf_output

#
mkdir -p ${DOCKER_CERTS_DIR}

touch $outfile $docker_key_file $docker_ca_cert_file $docker_cert_file $tf_data $outfile_docker

# get outputs es_admin node
comp=es_admin
sh run.sh ${ENVIRONMENT_NAME} output ${comp} > $tf_data

# Blank out docker props file
echo '#/bin/bash' > $outfile_docker

# set docker host
export ES_DOCKER_HOST=$(cat $tf_data | grep es_admin_host | cut -d ' ' -f3)
echo "export ES_DOCKER_HOST=${ES_DOCKER_HOST}" >> $outfile_docker

aws ssm put-parameter \
    --name "${SSM_TASKS_PREFIX}/${ENVIRONMENT_NAME}/docker_host" \
    --description "build properties" \
    --value "${ES_DOCKER_HOST}" \
    --type "String" \
    --overwrite


export CONFIG_BUCKET=$(cat $tf_data | grep config_bucket | cut -d ' ' -f3)
echo "export CONFIG_BUCKET=${CONFIG_BUCKET}" >> $outfile_docker

aws ssm put-parameter \
    --name "${SSM_TASKS_PREFIX}/${ENVIRONMENT_NAME}/config_bucket" \
    --description "build properties" \
    --value "${CONFIG_BUCKET}" \
    --type "String" \
    --overwrite

export ALF_BACKUP_BUCKET=$(cat $tf_data | grep backups_bucket | cut -d ' ' -f3)
echo "export ALF_BACKUP_BUCKET=${ALF_BACKUP_BUCKET}" >> $outfile_docker


export ELK_BACKUP_BUCKET=$(cat $tf_data | grep elk_bucket_name | cut -d ' ' -f3)
echo "export ELK_BACKUP_BUCKET=${ELK_BACKUP_BUCKET}" >> $outfile_docker


export ELK_S3_REPO_NAME=$(cat $tf_data | grep elk_s3_repo_name | cut -d ' ' -f3)
echo "export ELK_S3_REPO_NAME=${ELK_S3_REPO_NAME}" >> $outfile_docker

export ES_LB_DNS=$(cat $tf_data | grep elk_lb_dns | cut -d ' ' -f3)
echo "export ES_LB_DNS=${ES_LB_DNS}" >> $outfile_docker



export ES_SNAPSHOT_NAME=$(cat $tf_data | grep es_snapshot_name | cut -d ' ' -f3)
echo "export ES_SNAPSHOT_NAME=${ES_SNAPSHOT_NAME}" >> $outfile_docker
echo "export ES_MIGRATION_SNAPSHOT_NAME=migration_${ES_SNAPSHOT_NAME}" >> $outfile_docker


export ALF_ASG_PREFIX=$(cat $tf_data | grep asg_prefix | cut -d ' ' -f3)
echo "export ALF_ASG_PREFIX=${ALF_ASG_PREFIX}" >> $outfile_docker


export ALF_STORAGE_BUCKET=$(cat $tf_data | grep storage_s3bucket | cut -d ' ' -f3)
echo "export ALF_STORAGE_BUCKET=${ALF_STORAGE_BUCKET}" >> $outfile_docker


export ALF_RESTORE_STATUS=$(cat $tf_data | grep alf_restore_status | cut -d ' ' -f3)
echo "export ALF_RESTORE_STATUS=${ALF_RESTORE_STATUS}" >> $outfile_docker


# RDS
export ALF_DB_HOST=$(cat $tf_data | grep alf_db_host | cut -d ' ' -f3)
echo "export ALF_DB_HOST=${ALF_DB_HOST}" >> $outfile_docker


export ALF_DB_NAME=$(cat $tf_data | grep alf_db_name | cut -d ' ' -f3)
echo "export ALF_DB_NAME=${ALF_DB_NAME}" >> $outfile_docker


export ALF_DB_PASSWORD_SSM=$(cat $tf_data | grep alf_db_password_ssm | cut -d ' ' -f3)
echo "export ALF_DB_PASSWORD_SSM=${ALF_DB_PASSWORD_SSM}" >> $outfile_docker


export ALF_DB_USERNAME_SSM=$(cat $tf_data | grep alf_db_username_ssm | cut -d ' ' -f3)
echo "export ALF_DB_USERNAME_SSM=${ALF_DB_USERNAME_SSM}" >> $outfile_docker


# AWS
echo "export TERRAGRUNT_IAM_ROLE=$(cat $tf_data | grep terragrunt_iam_role | cut -d ' ' -f3)" >> $outfile_docker


echo "export TG_REGION=$(cat $tf_data | grep region | cut -d ' ' -f3)" >> $outfile_docker

##################################################################################################
# set elasticsearch host
# ES HOST
comp=elk-migration
sh run.sh ${ENVIRONMENT_NAME} output ${comp} > $tf_data
echo "export ES_MIGRATION_HOST=$(cat $tf_data | grep public_es_host_name | cut -d ' ' -f3)" >> $outfile_docker

##################################################################################################
# get cert details
comp=certs
sh run.sh ${ENVIRONMENT_NAME} output ${comp} > $tf_data

export SSM_CA_CERT=$(cat $tf_data | grep self_signed_ca_ssm_cert_pem_name | cut -d ' ' -f3)
export SSM_CERT=$(cat $tf_data | grep self_signed_server_ssm_cert_pem_name | cut -d ' ' -f3)
export SSM_PRIVATE_KEY=$(cat $tf_data | grep self_signed_server_ssm_private_key_name | cut -d ' ' -f3)

# set target account settings
eval $(cat env_configs/${ENVIRONMENT_NAME}/${ENVIRONMENT_NAME}.properties | grep TERRAGRUNT_IAM_ROLE)
eval $(cat env_configs/${ENVIRONMENT_NAME}/${ENVIRONMENT_NAME}.properties | grep TG_REGION)

aws ssm put-parameter \
    --name "${SSM_TASKS_PREFIX}/${ENVIRONMENT_NAME}/ssm_ca_cert" \
    --description "build properties" \
    --value "${SSM_CA_CERT}" \
    --type "String" \
    --overwrite

aws ssm put-parameter \
    --name "${SSM_TASKS_PREFIX}/${ENVIRONMENT_NAME}/ssm_cert" \
    --description "build properties" \
    --value "${SSM_CERT}" \
    --type "String" \
    --overwrite

aws ssm put-parameter \
    --name "${SSM_TASKS_PREFIX}/${ENVIRONMENT_NAME}/ssm_private_key" \
    --description "build properties" \
    --value "${SSM_PRIVATE_KEY}" \
    --type "String" \
    --overwrite

echo "syncing files"
cp $outfile_docker ./scripts/docker.properties
ansible-playbook pipelines/tasks/ansible/upload_scripts_playbook.yml 

# complete
echo "Environment settings"
cat $outfile_docker
