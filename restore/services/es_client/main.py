import json
from app.helpers import string_replacer

from app.elasticsearch_app.snapshot import Elasticsearch_Snapshot_Handler
from app.elasticsearch_app.indices import Elasticsearch_Indices_Handler

es_snapshot = Elasticsearch_Snapshot_Handler()
es_indices = Elasticsearch_Indices_Handler()

old_pattern = "logstash-production_logs"
new_pattern = "alfresco-logstash"

es_repository_name = es_snapshot.repository_name

artefact_name = "{}-{}".format(es_repository_name, new_pattern).lower()

logstash_indices = es_indices.get_indices_matching_pattern(old_pattern)

print("Found {} indices matching search pattern {}".format(
    len(logstash_indices),
    old_pattern
))


def manage_repo(repository):
    response = es_snapshot.create_repository(repository)
    print(response)


def delete(index_name):
    if es_indices.check_index_exists(index_name):
        response = es_indices.delete_index(index_name)
        print(response)


def main():
    for src_index in logstash_indices:
        destination_index = string_replacer(
            (
                src_index,
                old_pattern,
                new_pattern
            )
        )
        print("Running reindex on index: {}".format(src_index))
        es_indices.delete_index(destination_index)
        result = json.loads(es_indices.index_reindex(
            src_index, destination_index))
        if result['acknowledged']:
            print("Success reindexing {}".format(src_index))
            result_delete = json.loads(es_indices.delete_index(src_index))
            if result_delete:
                print("Index {} deleted".format(src_index))


def create_snapshot(snapshot_name):
    response = es_snapshot.create_snapshot(snapshot_name.lower())
    print(response)


if __name__ == "__main__":
    #     # execute only if run as a script
    manage_repo(es_repository_name)
    delete('.kibana')
    main()
    create_snapshot(artefact_name)
