import time
import os 

from app.docker import update_task_status

counter = 0

if __name__ in "__main__":
    es_task_ttl = int(os.environ.get("ES_TASK_TTL") or 60)
    while True:
      update_task_status(es_task_ttl)
      time.sleep(es_task_ttl)

