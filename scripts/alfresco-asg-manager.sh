#!/bin/bash 

set +e

if [ -z "${ALF_RESTORE_STATUS}" ]
then
    ALF_RESTORE_STATUS="no-restore"
fi

echo "Restore mode is: ${ALF_RESTORE_STATUS}"

if [ ${ALF_RESTORE_STATUS} = restore ]
then
  echo "Bring down ASG"
  asg-manager asg_update --size 0 --check ${ALF_ASG_PREFIX} && echo Success || exit $?
  echo "------> ASG Handler done"

else
  echo "Run mode set to ${ALF_RESTORE_STATUS}, dry-run flags set"
  echo "command: asg-manager asg_update --size 0 --check ${ALF_ASG_PREFIX}"
  echo "------> ASG Handler Dry Run Done"
fi

set -e