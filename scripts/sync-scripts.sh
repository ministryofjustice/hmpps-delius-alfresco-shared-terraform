#!/bin/bash 
set +e
aws s3 sync s3://${S3_BUCKET}/scripts /opt/scripts
set +e