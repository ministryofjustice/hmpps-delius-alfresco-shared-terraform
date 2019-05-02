aws s3 sync s3://tf-eu-west-2-hmpps-delius-test-alfresco-es-s3bucket/elasticsearch /opt/esbackup/

chown -R elasticsearch:elasticsearch /opt/esbackup

curl -XPUT 'http://localhost:9200/_snapshot/SR2_Backup' -H 'Content-Type: application/json' -d '{
    "type": "fs",
    "settings": {
        "location": "/opt/esbackup",
        "compress": true
    }
}'

curl -X POST http://localhost:9200/_snapshot/SR2_Backup/snapshot_sr2/_restore?pretty=true