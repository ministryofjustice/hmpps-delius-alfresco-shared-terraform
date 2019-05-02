from elasticsearch import Elasticsearch
from app.config import Config

from app.helpers import json_dumper

import os


class Elasticsearch_Handler(Config):

    def __init__(self):
        self._es_hosts = Config.es_host
        self.repository_path = Config.repository_path
        self.repository_name = Config.repository_name
        self.request_timeout = Config.request_timeout
        self._connection = None
        self.cluster_data = None

    @property
    def connection(self):
        conn = Elasticsearch([self._es_hosts])
        if conn.ping():
            self._connection = conn
            cluster_info = conn.cluster.state()
            self.cluster_data = {'cluster': cluster_info['cluster_name'],
                                 'master': cluster_info['master_node'],
                                 'nodes': cluster_info['nodes']
                                 }
        else:
            response_obj = {
                'operation': 'connection',
                'message': 'Error connecting to elasticsearch'
            }
            print(json_dumper(response_obj))
        return self._connection
