from elasticsearch import Elasticsearch
import os
import curator
import json
import logging
import time

log_level_name = os.environ.get('LOG_LEVEL', 'INFO')
wait_interval = int(os.environ.get('WAIT_INTERVAL', 60))
es_host = os.environ.get('ES_HOST')
es = Elasticsearch(es_host)

log_level = logging.getLevelName(log_level_name)
logging.basicConfig(format='%(asctime)s - %(message)s', level=log_level)

wait_for_cluster = True

while wait_for_cluster:
    cluster_health = es.cluster.health()
    percentage = float(round(cluster_health['active_shards_percent_as_number'], 2))
    state = cluster_health['status']
    if state == 'green' and percentage >= 99.99:
        logging.info('Cluster health now {}, ...exiting wait for cluster'.format(state))
        wait_for_cluster = False
    else:    
        logging.info('Waiting for cluster, health is currently {} and active shards {}%'.format(
            state,
            percentage
            )
        )
        time.sleep(wait_interval)
    
logging.info('done')
