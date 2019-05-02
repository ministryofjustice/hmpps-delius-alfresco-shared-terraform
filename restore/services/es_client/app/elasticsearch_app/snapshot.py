from app.elasticsearch_app import Elasticsearch_Handler

from app.helpers import json_dumper


class Elasticsearch_Snapshot_Handler(Elasticsearch_Handler):
    def __init__(self):
        super().__init__()
        self.snapshot_connection = self.connection.snapshot

    def check_snapshot_exists(self, snapshot_name):
        query = self.snapshot_connection.get(
            self.repository_name, ['_all'])
        snapshot_list = [snp['snapshot']
                         for snp in query['snapshots'] if snp['snapshot'] == snapshot_name]
        if snapshot_name in snapshot_list:
            return True
        return False

    def create_snapshot(self, snapshot_name, body_req=None):
        if body_req is None:
            body_req = {
                "indices": "_all",
                "ignore_unavailable": True,
                "include_global_state": False
            }
        es_procdure = 'create snapshot'
        repository_name = self.repository_name
        response_obj = {
            'repository': repository_name,
            'acknowledged': False,
            'message': 'repository not found'
        }
        self.create_repository(repository_name)
        if self.check_snapshot_exists(snapshot_name):
            self.delete_snapshot(snapshot_name)
            response_obj.update(
                {'snapshot': 'found and deleting existing snapshot',
                 'message': 'repository found'}
            )
        response = self.snapshot_connection.create(
            repository_name, snapshot_name, body=body_req,
            wait_for_completion=False)
        if response['accepted'] == True:
            response_obj.update(
                {
                    'snapshot': snapshot_name,
                    'message': 'snapshot create task submitted',
                    'acknowledged': True,
                }
            )
        return json_dumper(response_obj, es_procdure)

    def delete_snapshot(self, snapshot_name):
        es_procdure = 'delete snapshot'
        repository_name = self.repository_name
        response_obj = {
            'snapshot': snapshot_name,
            'acknowledged': False,
            'repository': repository_name,
            'message': 'snapshot not found'
        }
        if self.check_snapshot_exists(snapshot_name):
            response = self.snapshot_connection.delete(
                repository_name,
                snapshot_name
            )
            if response['acknowledged']:
                response_obj.update(
                    {'snapshot': snapshot_name,
                     'acknowledged': True,
                     'message': 'snapshot deleted'
                     }
                )
        return json_dumper(response_obj, es_procdure)

    def check_repository_exists(self, repository_name):
        query = self.snapshot_connection.get_repository()
        if repository_name in query.keys():
            return True
        return False

    def create_repository(self, repository_name):
        es_procdure = 'create repository'
        response_obj = {
            'repository': repository_name,
            'acknowledged': False,
            'message': 'repository already exists'
        }
        if not self.check_repository_exists(repository_name):
            body = {
                "type": "fs",
                "settings": {
                    "location": self.repository_path,
                    "compress": True
                }
            }
            response = self.snapshot_connection.create_repository(
                repository_name,
                body=body)
            if response['acknowledged']:
                response_obj = {
                    'repository': repository_name,
                    'acknowledged': True,
                    'message': 'repository created'
                }
        return json_dumper(response_obj, es_procdure)

    def delete_repository(self, repository_name):
        es_procdure = 'delete repository'
        response_obj = {
            'repository': repository_name,
            'acknowledged': False,
            'message': 'repository not found'
        }
        if self.check_repository_exists(repository_name):
            response = self.snapshot_connection.delete_repository(
                repository_name)
            if response['acknowledged']:
                response_obj = {
                    'repository': repository_name,
                    'acknowledged': True,
                    'message': 'repository deleted'
                }
        return json_dumper(response_obj, es_procdure)
