#!/bin/bash 
set +e
artefacts_bucket = tf-eu-west-2-hmpps-eng-prod-artefacts-s3bucket
database_files = Prod/Alfresco_PGS_14092019/
file-path=/Prod/Alfresco_gluster_14092019/
elk-path=Prod/elk_backups_14092019/
holding_bucket = tf-eu-west-2-hmpps-delius-prod-alfresco-s3bucket
set -e
