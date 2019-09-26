#!/bin/bash 
set +e
aws s3 sync --delete s3://${S3_BUCKET}/scripts/ /opt/scripts/ && echo Success || exit $?
set +e
