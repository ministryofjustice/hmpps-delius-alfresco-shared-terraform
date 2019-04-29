import pytest


def test_es_connection(es_conn):
    info = es_conn.info()
    assert type(info) is dict
    assert info['tagline'] == 'You Know, for Search'
    assert info['cluster_name'] == 'es-clust'


def test_config(config):
    assert type(config.request_timeout) == int
    assert config.repository_name == 'test'
    assert config.es_host == 'elasticsearch'
