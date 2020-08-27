#!/bin/sh

set -e

#Usage
# Scripts takes 2 arguments: environment_name and action
# environment_name: target environment example dev prod
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

if [ -z "${HMPPS_BUILD_WORK_DIR}" ]
then
    echo "--> Using default workdir"
    env_config_dir="${HOME}/data/env_configs"
else
    echo "USING CUSTOM WORKDIR for configs: $HMPPS_BUILD_WORK_DIR"
    env_config_dir="${HMPPS_BUILD_WORK_DIR}/env_configs"
fi

ENVIRONMENT_NAME_ARG=$1
ACTION_TYPE=$2
COMPONENT=${3}


if [ -z "${ENVIRONMENT_NAME_ARG}" ]
then
    echo "environment_name argument not supplied, please provide an argument!"
    exit 1
fi

echo "Output -> environment_name set to: ${ENVIRONMENT_NAME_ARG}"

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
if [[ ${RUNNING_IN_CONTAINER:-False} == True ]]
then
    mkdir -p /home/tools/data/lambda
    workDirContainer=${3}
    echo "Output -> environment stage"
    source ${env_config_dir}/${ENVIRONMENT_NAME_ARG}/${ENVIRONMENT_NAME_ARG}.properties
    exit_on_error $? !!
    echo "Output ---> set environment stage complete"
    # set runCmd
    ACTION_TYPE="docker-${ACTION_TYPE}"
    export workDir=${workDirContainer}
    cd ${workDir}
    export PLAN_RET_FILE=${HOME}/data/${workDirContainer}_plan_ret
    echo "Output -> Container workDir: ${workDir}"
fi

#Apply overrides if names are too long
if [ -f "${env_config_dir}/${ENVIRONMENT_NAME_ARG}/sub-projects/alfresco.properties" ]; then
    echo "Applying ENV overrides"
    source ${env_config_dir}/${ENVIRONMENT_NAME_ARG}/sub-projects/alfresco.properties;
fi

if [ ${COMPONENT} == "ami_permissions" ]
then 
  export TERRAGRUNT_IAM_ROLE="arn:aws:iam::895523100917:role/terraform"
  export TG_REMOTE_STATE_BUCKET="tf-eu-west-2-hmpps-eng-dev-remote-state"
  export TG_ENVIRONMENT_IDENTIFIER="tf-eu-west-2-hmpps-eng-dev"
  echo "Using engineering role: ${TERRAGRUNT_IAM_ROLE}"
fi

case ${ACTION_TYPE} in
  docker-ansible)
    echo "Running ansible playbook action"
    ansible-playbook playbook.yml
    exit_on_error $? !!
    ;;
  docker-plan)
    echo "Running docker plan action"
    rm -rf .terraform *.plan
    terragrunt init
    exit_on_error $? !!
    terragrunt plan -detailed-exitcode --out ${ENVIRONMENT_NAME_ARG}.plan || export tf_exit_code="$?"
    if [ -z ${tf_exit_code} ]
    then
      export tf_exit_code="0"
    fi
    echo "export exitcode=${tf_exit_code}" > ${PLAN_RET_FILE}
    exit_on_error $? !!
    ;;
  docker-apply)
    echo "Running docker apply action"
    terragrunt apply ${ENVIRONMENT_NAME_ARG}.plan || export tf_exit_code="$?"
    if [ -z ${tf_exit_code} ]
    then
      export tf_exit_code="0"
    fi
    echo "export exitcode=${tf_exit_code}" > ${PLAN_RET_FILE}
    ;;
  docker-destroy)
    echo "Running docker destroy action"
    rm -rf .terraform *.plan
    terragrunt init
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
    echo "Running docker output action"
    rm -rf .terraform *.plan
    terragrunt init
    terragrunt output
    exit_on_error $? !!
    ;;
  docker-json)
    echo "Running docker output action"
    rm -rf .terraform *.plan
    terragrunt init
    terragrunt output -json > data.json
    exit_on_error $? !!
    ;;
  *)
    echo "${ACTION_TYPE} is not a valid argument. init - apply - test - output - destroy"
  ;;
esac
