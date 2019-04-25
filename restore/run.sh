#!/bin/sh 

mkdir /opt/elasticsearch/data \
    /opt/elasticsearch/logs \
    /opt/backups

aws s3 sync s3://tf-hmpps-del-test-mig-clust-staging-bucket/elasticsearch/ /opt/backup

chown -R elasticsearch:elasticsearch /opt/backup

docker-compose -f docker-compose.yml stop 

docker-compose -f docker-compose.yml rm -f 

docker-compose -f docker-compose.yml up --build -d

curl -X PUT http://localhost:19200/_snapshot/SR2_Backup?pretty=true  \
    -d '{     "type": "fs",     "settings": { "location": "/opt/backup"     }    }'

curl -X POST http://localhost:19200/_snapshot/SR2_Backup/snapshot_sr2/_restore?pretty=true