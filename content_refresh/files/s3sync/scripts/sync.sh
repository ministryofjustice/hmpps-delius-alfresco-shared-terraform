#!/bin/bash

aws configure set default.s3.max_concurrent_requests 50

TASK_PREFIX=${TASK_PREFIX}
SOURCE_BUCKET="s3://${SRC_BUCKET}"
DEST_BUCKET="s3://${DST_BUCKET}"

BUCKET_PATH="contentstore/${TASK_PREFIX}"
echo "---> STAGE 1 SYNCING MONTH ${BUCKET_PATH}"
aws s3 sync --delete ${SOURCE_BUCKET}/${BUCKET_PATH}/ ${DEST_BUCKET}/${BUCKET_PATH}/
BUCKET_PATH_BASE="${TASK_PREFIX}"
echo "---> STAGE 2 SYNCING MONTH ${BUCKET_PATH_BASE}"
aws s3 sync --delete ${SOURCE_BUCKET}/${BUCKET_PATH_BASE}/ ${DEST_BUCKET}/${BUCKET_PATH_BASE}/
echo "---> COMPLETED SYNCING MONTH ${TASK_PREFIX}"