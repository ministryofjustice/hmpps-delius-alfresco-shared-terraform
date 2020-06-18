# app/task_handler.py

import json

from rq import Queue
from app.config import Config
from task_submit import submit_copy_task
from app.helpers import generate_task_list
from app.clients import _redis_conn

conn = _redis_conn()

q = Queue(connection=conn)


def lambda_handler(event, context):
    source_bucket = event["source_bucket"]
    destination_bucket = event["destination_bucket"]
    task_dict = {
        "source": source_bucket,
        "destination": destination_bucket
    }
    for task in generate_task_list():
        task_dict["prefix"] = task
        q.enqueue(submit_copy_task, task_dict)

    return task_dict


# if __name__ == "__main__":
#     submitted_tasks = []
#     source_bucket = Config.source_bucket
#     destination_bucket = Config.destination_bucket
#     task_dict = {
#         "source": source_bucket,
#         "destination": destination_bucket
#     }
#     for task in generate_task_list():
#         task_dict["prefix"] = task
#         q.enqueue(submit_copy_task, task_dict)
#         submitted_tasks.append(task_dict)

#     print(submitted_tasks)
