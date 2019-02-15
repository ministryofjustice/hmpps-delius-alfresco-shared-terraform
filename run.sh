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
ACTION_TYPE=$2
COMPONENT=${3}
REPO=${4}


if [ -z "${TG_ENVIRONMENT_TYPE}" ]
then
    echo "environment_type argument not supplied, please provide an argument!"
    exit 1 
fi

echo "Output -> environment_type set to: ${TG_ENVIRONMENT_TYPE}"

if [ -z "${ACTION_TYPE}" ]
then
    echo "ACTION_TYPE argument not supplied."
    echo "--> Defaulting to plan ACTION_TYPE"
    ACTION_TYPE="plan"
fi

echo "Output -> ACTION_TYPE set to: ${ACTION_TYPE}"

if [ -z "${COMPONENT}" ]
then
    echo "COMPONENT argument not supplied."
    echo "--> Defaulting to common component"
    COMPONENT="common"
fi

#check env vars for RUNNING_IN_CONTAINER switch
if [[ ${RUNNING_IN_CONTAINER} == True ]]
then
    workDirContainer=${3}
    echo "Output -> clone configs stage"
    rm -rf ${env_config_dir}
    echo "Output ---> Cloning branch: ${GIT_BRANCH}"
    git clone -b ${GIT_BRANCH} ${REPO} ${env_config_dir}
    echo "Output -> environment stage"
    source ${env_config_dir}/${TG_ENVIRONMENT_TYPE}/${TG_ENVIRONMENT_TYPE}.properties
    exit_on_error $? !!
    echo "Output ---> set environment stage complete"
    # set runCmd
    ACTION_TYPE="docker-${ACTION_TYPE}"
    cd ${workDirContainer}
    echo "Output -> Container workDir: $(pwd)"
fi

case ${ACTION_TYPE} in
  docker-plan)
    echo "Running docker plan action"
    rm -rf .terraform *.plan
    terragrunt init
    exit_on_error $? !!
    terragrunt plan -detailed-exitcode --out ${TG_ENVIRONMENT_TYPE}.plan
    exit_on_error $? !!
    ;;
  docker-apply)
    echo "Running docker apply action"
    terragrunt apply ${TG_ENVIRONMENT_TYPE}.plan
    exit_on_error $? !!
    ;;
  docker-destroy)
    echo "Running docker destroy action"
    terragrunt destroy -force
    exit_on_error $? !!
    ;;
  docker-test)
    echo "Running docker test action"
    for cmp in ${components_list}
    do
      output_file="${inspec_profile_files_path}/output-${cmp}.json"
      rm -rf ${output_file}
      cd ${workingDir}/${cmp}
      terragrunt output -json > ${output_file}
      exit_on_error $? !!
    done
    exit_on_error $? !!
    temp_role=$(aws sts assume-role --role-arn ${TERRAGRUNT_IAM_ROLE} --role-session-name testing --duration-seconds 900)
    echo "unset AWS_PROFILE
    export AWS_ACCESS_KEY_ID=$(echo ${temp_role} | jq .Credentials.AccessKeyId | xargs)
    export AWS_SECRET_ACCESS_KEY=$(echo ${temp_role} | jq .Credentials.SecretAccessKey | xargs)
    export AWS_SESSION_TOKEN=$(echo ${temp_role} | jq .Credentials.SessionToken | xargs)" > ${inspec_creds_file}
    source ${inspec_creds_file}
    exit_on_error $? !!
    cd ${workingDir}
    inspec exec ${inspec_profile} -t aws://${TG_REGION}
    exit_on_error $? !!
    rm -rf ${inspec_creds_file} ${inspec_profile_files_path}/output*.json
    ;;
  docker-output)
    echo "Running docker apply action"
    terragrunt output
    exit_on_error $? !!
    ;;
  *)
    echo "${ACTION_TYPE} is not a valid argument. init - apply - test - output - destroy"
  ;;
esac