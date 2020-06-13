#!/bin/bash

# yum install screen -y
# screen -s 2016
# sh sync.sh 2016 6 9

aws configure set default.s3.max_concurrent_requests 250

# YEAR=${1}

# MONTH=${2}

SOURCE_BUCKET="s3://${SRC_BUCKET}"
DEST_BUCKET="s3://${DST_BUCKET}"

BUCKET_PATH="contentstore/${YEAR}/${MONTH}"
echo "---> STAGE 1 SYNCING MONTH ${BUCKET_PATH}"
aws s3 sync --delete ${SOURCE_BUCKET}/${BUCKET_PATH}/ ${DEST_BUCKET}/${BUCKET_PATH}/
BUCKET_PATH_BASE="${YEAR}/${MONTH}"
echo "---> STAGE 2 SYNCING MONTH ${BUCKET_PATH_BASE}"
aws s3 sync --delete ${SOURCE_BUCKET}/${BUCKET_PATH_BASE}/ ${DEST_BUCKET}/${BUCKET_PATH_BASE}/
echo "---> COMPLETED SYNCING MONTH ${YEAR}/${MONTH}"
