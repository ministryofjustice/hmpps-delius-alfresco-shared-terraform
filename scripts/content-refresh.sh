#!/bin/bash

# yum install screen -y
# screen -s 2016
# sh sync.sh 2016 6 9

aws configure set default.s3.max_concurrent_requests 250

YEAR=${1}
if [ -z "${YEAR}" ]
then
    echo "YEAR argument not supplied."
    exit 1
fi

START=${2}
if [ -z "${START}" ]
then
    echo "START month argument not supplied."
    exit 1
fi

END=${3}
if [ -z "${END}" ]
then
    echo "END month argument not supplied."
    exit 1
fi



SOURCE_BUCKET="s3://tf-eu-west-2-hmpps-delius-prod-alfresco-storage-s3bucket"
DEST_BUCKET="s3://tf-eu-west-2-hmpps-delius-pre-prod-alfresco-storage-s3bucket"

for i in $(eval echo "{$START..$END}")
do
    BUCKET_PATH="contentstore/${YEAR}/${i}"
    echo "---> STAGE 1 SYNCING MONTH ${BUCKET_PATH}"
    aws s3 sync ${SOURCE_BUCKET}/${BUCKET_PATH}/ ${DEST_BUCKET}/${BUCKET_PATH}/
    BUCKET_PATH_BASE="${YEAR}/${i}"
    echo "---> STAGE 2 SYNCING MONTH ${BUCKET_PATH_BASE}"
    aws s3 sync ${SOURCE_BUCKET}/${BUCKET_PATH_BASE}/ ${DEST_BUCKET}/${BUCKET_PATH_BASE}/
    echo "---> COMPLETED SYNCING MONTH ${YEAR}/${i}"
done
