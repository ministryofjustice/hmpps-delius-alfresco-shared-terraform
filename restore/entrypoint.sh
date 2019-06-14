#!/bin/sh 

# aws s3 sync s3://${S3_BUCKET}/elasticsearch/ /opt/es_backup

# chown -R elasticsearch:elasticsearch /opt/es_backup

# chmod 777 /opt/es_backup

elasticsearch-manager --help