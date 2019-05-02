import pytest
import json


def test_check_snapshot_exists_returns_false(snapshot_create_repo, snapshot, snapshot_delete, es_objects):
    snapshot_name = es_objects['snapshot_name']
    response = snapshot.check_snapshot_exists(snapshot_name)
    assert response == False


def test_check_snapshot_exists_returns_true(snapshot, snapshot_create, es_objects):
    snapshot_name = es_objects['snapshot_name']
    response = snapshot.check_snapshot_exists(snapshot_name)
    assert response == True


def test_create_snapshot_passes_with_no_body(snapshot, snapshot_delete, es_objects):
    snapshot_name = es_objects['snapshot_name']
    response = json.loads(snapshot.create_snapshot(snapshot_name))
    assert response['acknowledged'] == True
    assert response['message'] == 'snapshot create task submitted'


def test_create_snapshot_passes_with_body(snapshot, snapshot_delete, es_objects):
    snapshot_name = es_objects['snapshot_name']
    snapshot_body = es_objects['snapshot_body']
    response = json.loads(snapshot.create_snapshot(
        snapshot_name, snapshot_body))
    assert response['acknowledged'] == True
    assert response['message'] == 'snapshot create task submitted'


def test_delete_snapshot_returns_false(snapshot, snapshot_delete, es_objects):
    snapshot_name = es_objects['snapshot_name']
    response = json.loads(snapshot.delete_snapshot(snapshot_name))
    assert response['acknowledged'] == False
    assert response['message'] == 'snapshot not found'
    assert response['snapshot'] == snapshot_name


def test_delete_snapshot_returns_true(snapshot, snapshot_create, es_objects):
    snapshot_name = es_objects['snapshot_name']
    response = json.loads(snapshot.delete_snapshot(snapshot_name))
    assert response['acknowledged'] == True
    assert response['message'] == 'snapshot deleted'
    assert response['snapshot'] == snapshot_name


def test_check_repository_exists_returns_false_when_no_repository_found(snapshot, snapshot_delete_repo, es_objects):
    repo_name = es_objects['repo_name']
    response = snapshot.check_repository_exists(repo_name)
    assert response == False


def test_check_repository_exists_return_true(snapshot_create_repo, snapshot, es_objects):
    repo_name = es_objects['repo_name']
    response = snapshot.check_repository_exists(repo_name)
    assert response == True


def test_delete_repository_return_false_when_none_existent(snapshot, es_objects):
    repo_name = es_objects['repo_name']
    response = json.loads(snapshot.delete_repository(repo_name))
    assert response['acknowledged'] == False


def test_delete_repository_returns_true(snapshot, snapshot_create_repo, es_objects):
    repo_name = es_objects['repo_name']
    response = json.loads(snapshot.delete_repository(repo_name))
    assert response['acknowledged'] == True
