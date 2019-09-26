import os

from app.elasticsearch_app.indices import Elasticsearch_Indices_Handler
from app.elasticsearch_app.snapshot import Elasticsearch_Snapshot_Handler

migration_bucket = os.environ.get('CONFIG_BUCKET')
elk_backup_bucket = os.environ.get('ELK_BACKUP_BUCKET')
elk_repo_name = os.environ.get('ELK_S3_REPO_NAME')
create_migration_repo = os.environ.get('CREATE_MIGRATION_REPO', False)

es_snapshot = Elasticsearch_Snapshot_Handler()
es_indices = Elasticsearch_Indices_Handler()

migration_obj = {
    'repository': 'local',
    'type': 's3', 
    'base_path': 'restore/elasticsearch',
    'bucket': migration_bucket
}

elk_cluster_obj = {
    'repository': elk_repo_name,
    'type': 's3',
    'bucket': elk_backup_bucket
}

# create local repo
if create_migration_repo:
    es_snapshot.create_repository(migration_obj)

# create elk repo
es_snapshot.create_repository(elk_cluster_obj)
