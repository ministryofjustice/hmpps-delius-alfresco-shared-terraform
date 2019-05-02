import pytest
import json


def test_check_index_exists_fails_when_no_index_found(indices, es_objects):
    index_name = es_objects['index_name']
    response = indices.check_index_exists(index_name)
    assert response == False


def test_check_index_exists_passes_when_index_found(indices, es_objects):
    index_name = es_objects['index_name']
    response = indices.check_index_exists(index_name)
    assert response == False


def test_get_indices(indices, indices_create_index):
    response = indices.get_indices()
    assert type(response) is dict


def test_get_all_indices(indices, indices_create_index):
    response = indices.get_all_indices()
    assert type(json.loads(response))


def test_create_index_success(indices, es_objects, indices_delete_index):
    index_name = es_objects['index_name']
    index_body = es_objects['index_body']
    mappings = index_body['mappings']
    response = json.loads(indices.create_index(index_name, index_body))
    check_response = json.loads(indices.get_index(index_name))
    assert response['acknowledged'] == True
    assert response['index'] == index_name
    assert response['message'] == 'index created'
    assert check_response[index_name]['mappings'] == mappings


def test_create_index_fails_when_index_exists(indices, es_objects, indices_create_index):
    index_name = es_objects['index_name']
    index_body = es_objects['index_body']
    response = json.loads(indices.create_index(index_name, index_body))
    assert response['acknowledged'] == False


def test_delete_index_fails_when_none_existent(indices, es_objects):
    index_name = es_objects['index_name']
    response = json.loads(indices.delete_index(index_name))
    assert response['acknowledged'] == False


def test_delete_index_success(indices, es_objects, indices_create_index):
    index_name = es_objects['index_name']
    response = json.loads(indices.delete_index(index_name))
    assert response['acknowledged'] == True

# def test_delete_repository_success(snapshot, snapshot_create_repo, snapshot_oject):
#     repo_name = snapshot_oject['repo_name']
#     response = json.loads(snapshot.delete_repository(repo_name))
#     assert response['acknowledged'] == True
