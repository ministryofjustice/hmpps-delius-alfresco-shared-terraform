#!/bin/bash 

set +e

if [ -z "${RUN_MODE}" ]
then
    RUN_MODE = false
fi

asg_name=${ALF_ASG_PREFIX}

echo "Bring down ASG"
asg-manager asg_update --size 0 ${asg_name} && echo Success || exit $?


echo "Run mode is: ${RUN_MODE}"

if [ ${RUN_MODE} = true ]
then
  echo "Run mode set to ${RUN_MODE}, no dry-run set"
  aws s3 rm s3://${ALF_STORAGE_BUCKET} --recursive && echo Success || exit $?
  aws s3 sync --only-show-errors s3://${CONFIG_BUCKET}/contentstore s3://${ALF_STORAGE_BUCKET}/contentstore && echo Success || exit $?
  aws s3 sync --only-show-errors s3://${CONFIG_BUCKET}/contentstore.deleted s3://${ALF_STORAGE_BUCKET}/contentstore.deleted && echo Success || exit $?
  echo "------> SYNC DONE"

else
  echo "Run mode set to ${RUN_MODE}, dry-run flags set"
  aws s3 rm s3://${ALF_STORAGE_BUCKET} --recursive --dryrun && echo Success || exit $?
  aws s3 sync s3://${CONFIG_BUCKET}/contentstore s3://${ALF_STORAGE_BUCKET}/contentstore --dryrun && echo Success || exit $?
  aws s3 sync s3://${CONFIG_BUCKET}/contentstore.deleted s3://${ALF_STORAGE_BUCKET}/contentstore.deleted --dryrun && echo Success || exit $?
  echo "------> DRY RUN SYNC DONE"
fi

set -e