#!/bin/bash 

set +e

if [ -z "${ALF_RESTORE_STATUS}" ]
then
    ALF_RESTORE_STATUS="no-restore"
fi

aws configure set default.s3.max_concurrent_requests 250

CONTENT_STORE_CMD="s3://${CONFIG_BUCKET}/restore/files/ s3://${ALF_STORAGE_BUCKET}/"

echo "Restore mode is: ${ALF_RESTORE_STATUS}"

if [ ${ALF_RESTORE_STATUS} = restore ]
then
  echo "Run mode set to ${ALF_RESTORE_STATUS}"
  echo "Source bucket: ${CONFIG_BUCKET}"
  echo "Storage bucket: ${ALF_STORAGE_BUCKET}"
  aws s3 sync --delete ${CONTENT_STORE_CMD}
  echo "------> SYNC DONE"

else
  echo "Run mode set to ${ALF_RESTORE_STATUS}, dry-run flags set"
  aws s3 sync --delete ${CONTENT_STORE_CMD} --dryrun
  echo "------> DRY RUN SYNC DONE"
fi

set -e
