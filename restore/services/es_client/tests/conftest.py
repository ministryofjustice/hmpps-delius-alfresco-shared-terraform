import pytest

from elasticsearch import Elasticsearch

from app.config import Config
from app.elasticsearch_app import Elasticsearch_Handler
from app.elasticsearch_app.snapshot import Elasticsearch_Snapshot_Handler
from app.elasticsearch_app.indices import Elasticsearch_Indices_Handler


def es_properties(scope='session'):

    es_obj = {
        'repo_name': 'test',
        'snapshot_name': 'test',
        'index_name': 'test',
        'dest_index': 'testcopy',
        'index_body': {
            'settings': {
                'number_of_shards': 5,
                'number_of_replicas': 1
            },
            'mappings': {
                'testcase': {
                    'properties': {
                        'address': {'type': 'keyword'},
                        'date_of_birth': {'format': 'dateOptionalTime', 'type': 'date'},
                        'email_domain': {'type': 'keyword'}
                    }
                }
            }
        },
        'snapshot_body': {
            "indices": "_all",
            "ignore_unavailable": True,
            "include_global_state": False
        }
    }
    return es_obj


@pytest.fixture(scope='session')
def config():
    return Config


@pytest.fixture(scope='session')
def es_conn():
    es_conn = Elasticsearch_Handler()
    return es_conn.connection


@pytest.fixture(scope='function')
def es_objects():
    return es_properties()


@pytest.fixture(scope='function')
def snapshot():
    snapshot = Elasticsearch_Snapshot_Handler()
    return snapshot


@pytest.fixture(scope='function')
def indices():
    indices = Elasticsearch_Indices_Handler()
    return indices


@pytest.fixture(scope='function')
def snapshot_create_repo(snapshot, es_objects):
    repo_name = es_objects['repo_name']
    snapshot.create_repository(repo_name)
    yield
    snapshot.delete_repository(repo_name)


@pytest.fixture(scope='function')
def snapshot_delete_repo(snapshot, es_objects):
    repo_name = es_objects['repo_name']
    snapshot.delete_repository(repo_name)
    yield
    snapshot.delete_repository(repo_name)


@pytest.fixture(scope='function')
def indices_create_index(indices, es_objects):
    index_name = es_objects['index_name']
    index_body = es_objects['index_body']
    indices.create_index(index_name, index_body)
    yield
    indices.delete_index(index_name)


@pytest.fixture(scope='function')
def indices_delete_index(indices, es_objects):
    index_name = es_objects['index_name']
    yield
    indices.delete_index(index_name)


@pytest.fixture(scope='function')
def snapshot_delete(snapshot, es_objects, snapshot_create_repo):
    snapshot_name = es_objects['snapshot_name']
    snapshot.delete_snapshot(snapshot_name)
    yield
    snapshot.delete_snapshot(snapshot_name)


@pytest.fixture(scope='function')
def snapshot_create(snapshot, es_objects):
    snapshot_name = es_objects['snapshot_name']
    snapshot_body = es_objects['snapshot_body']
    snapshot.create_snapshot(snapshot_name, snapshot_body)
    yield
    snapshot.delete_snapshot(snapshot_name)
