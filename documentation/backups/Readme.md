## Alfresco Backups

Alfresco content is held in AWS S3 bucket. The s3 bucket has versioning enabled, with life cycle rules attached.

Life cycles rules are controlled by env-configs:

 * Dev environments - common.tfvars
 * Prod - common-prod.tfvars

#### Terraform variables 


Variable | Use case | Affects
---------|----------|----------
transition_days | days before data moves to glacier storage | backup s3bucket
expiration_days | days before data is deleted from s3bucket | backup s3bucket
noncurrent version transition_days | days before versioned file is moved to Standard-IA | content s3bucket
noncurrent_version_transition_glacier_days | days before versioned file is moved to Standard-IA | content s3bucket

#### Example

```
alf_backups_config = {
  transition_days                            = 5  
  expiration_days                            = 14
  noncurrent_version_transition_days         = 30
  noncurrent_version_transition_glacier_days = 60
  noncurrent_version_expiration_days         = 90
}
```

## Jenkins

Jenkins runs the backup operations using a pipeline which runs daily

Alfresco-Backup-Pipeline [jenkins job](alfresco_backup_pipeline)

The pipeline task will:

* Create Postgres database using pg_dump of the RDS master instance
* Sync the Alfresco content-store s3bucket to a backup s3bucket
* Create an ElasticSearch Snapshot

## S3 Buckets LifeCycle rules

Below is an example of the Alfresco Dev environment

Bucket | Use Case | Lifecycle
-------|----------|----------
tf-alf-dev-elk-backups-s3bucket | Elasticsearch Backups | transition days and expiration days
tf-alfresco-dev-alfresco-alf-backups | Alfresco Database and Content | transition days and expiration days
/tf-alfresco-dev-alfresco-storage-s3bucket | Alfresco Content | noncurrent version rules