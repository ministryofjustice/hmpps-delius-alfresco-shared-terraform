#!/bin/bash 

set +e

if [ -z "${ALF_RESTORE_STATUS}" ]
then
    ALF_RESTORE_STATUS="no-restore"
fi

CONTENT_STORE_CMD="s3://${CONFIG_BUCKET}/restore/contentstore/ s3://${ALF_STORAGE_BUCKET}/contentstore/"
CONTENT_STORE_DELETED_CMD="s3://${CONFIG_BUCKET}/restore/contentstore.deleted/ s3://${ALF_STORAGE_BUCKET}/contentstore.deleted/"

echo "Restore mode is: ${ALF_RESTORE_STATUS}"

if [ ${ALF_RESTORE_STATUS} = restore ]
then
  echo "Bring down ASG"
  asg-manager asg_update --size 0 --check ${ALF_ASG_PREFIX} && echo Success || exit $?
  echo "Run mode set to ${ALF_RESTORE_STATUS}"
  aws s3 rm --only-show-errors s3://${ALF_STORAGE_BUCKET} --recursive
  aws s3 sync --only-show-errors ${CONTENT_STORE_CMD}
  aws s3 sync --only-show-errors ${CONTENT_STORE_DELETED_CMD}
  echo "------> SYNC DONE"

else
  echo "Run mode set to ${ALF_RESTORE_STATUS}, dry-run flags set"
  aws s3 rm s3://${ALF_STORAGE_BUCKET} --recursive --dryrun
  aws s3 sync ${CONTENT_STORE_CMD} --dryrun
  aws s3 sync ${CONTENT_STORE_DELETED_CMD} --dryrun
  echo "------> DRY RUN SYNC DONE"
fi

set -e