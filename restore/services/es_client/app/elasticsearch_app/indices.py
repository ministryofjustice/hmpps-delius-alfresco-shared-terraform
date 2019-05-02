from app.elasticsearch_app import Elasticsearch_Handler

from app.helpers import json_dumper


class Elasticsearch_Indices_Handler(Elasticsearch_Handler):
    def __init__(self):
        super().__init__()
        self.indices_connection = self.connection.indices
        self.cluster_connection = self.connection.cluster
        self.index_body = {
            'settings': {
                'number_of_shards': 1,
                'number_of_replicas': 1
            }
        }

    def check_index_exists(self, index_name):
        return self.indices_connection.exists(index_name)

    def get_all_indices(self):
        response = self.get_indices()
        return json_dumper(response)

    def get_indices(self):
        response = self.cluster_connection.state()['metadata']['indices']
        return response

    def create_index(self, index_name, body=None):
        if body is None:
            body = self.index_body
        task = 'create index'
        response = {
            'acknowledged': False,
            'index': index_name,
            'message': 'index already exists'
        }
        if not self.check_index_exists([index_name]):
            response = self.indices_connection.create(
                index=index_name,
                body=body
            )
            if response['acknowledged']:
                response.update({'message': 'index created'})
                response.update({'acknowledged': True})
        return json_dumper(response, task)

    def delete_index(self, index_name):
        task = 'delete index'
        response = {
            'acknowledged': False,
            'index': index_name,
            'message': 'index not found'
        }
        if self.check_index_exists([index_name]):
            response = self.indices_connection.delete(index=index_name)
            if response['acknowledged']:
                response.update({'message': 'index deleted'})
                response.update({'acknowledged': True})
        return json_dumper(response, task)

    def get_index(self, index_name):
        response = {
            'acknowledged': False,
            'index': index_name,
            'message': 'index not found',
            'operation': 'get index'
        }
        check_index = self.check_index_exists(index_name)
        if check_index:
            response = self.indices_connection.get([index_name])
        return json_dumper(response)

    def get_indices_matching_pattern(self, pattern):
        indices_state = self.get_indices()
        response = [source_index for source_index in sorted(indices_state.keys(), reverse=True)
                    if pattern in source_index and indices_state[source_index]['state'] == 'open']
        return response

    def index_reindex(self, src_index, destination_index):
        task = 'reindex'
        response = {
            'acknowledged': False,
            'message': 'reindex task not completed',
            'src_index': src_index,
        }
        if self.check_index_exists([src_index]):
            response.update({'message': 'index found but not reindexed'})
            result = self.connection.reindex({
                "source": {"index": src_index},
                "dest": {"index": destination_index}
            }, wait_for_completion=True, request_timeout=300)

            if result['total'] and result['took'] and not result['timed_out']:
                response.update({'message': 'reindex task completed'})
                response.update({'acknowledged': True})
                response.update({'index': destination_index})
        return json_dumper(response, task)
