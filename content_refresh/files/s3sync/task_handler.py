# app/task_handler.py

import json

from rq import Queue
from app.config import Config
from app.docker import run_sync_task
from app.helpers import generate_task_list
from app.clients import _redis_conn

conn = _redis_conn()

q = Queue(connection=conn)


def lambda_handler(event, context):
    source_bucket = Config.source_bucket
    destination_bucket = Config.destination_bucket
    task_dict = {
        "source": source_bucket,
        "destination": destination_bucket
    }
    for task in generate_task_list():
        task_dict["prefix"] = task
        q.enqueue(run_sync_task, task_dict, job_timeout=7200)

    return task_dict


if __name__ == "__main__":
    lambda_handler(task_dict={}, context={})
