# task_submit.py

from app.s3bucket.list_bucket import handler as list_bucket
from app.s3bucket.copy_keys import handler as copy_handler
from app.helpers.logger import log_handler
from rq import Queue
from worker import conn

q = Queue(connection=conn)
logger = log_handler()


def submit_copy_task(task: dict):
    RUN_LOOP = True
    bucket_obj = {
        "bucket": task["source"],
        "prefix": task["prefix"]
    }
    logger.info("Start sync task")
    while RUN_LOOP == True:
        result = list_bucket(bucket_obj)

        task_obj = {
            "source": task["source"],
            "destination": task["destination"],
            "keys": result["keys"]
        }

        logger.info(str(task_obj))

        q.enqueue(copy_handler, task_obj)

        if "token" in result.keys():
            token = result.get("token")
            if token != "":
                bucket_obj["token"] = token
            else:
                RUN_LOOP = False

    RUN_LOOP = True
    bucket_obj = {
        "bucket": task["bucket"],
        "prefix": task["prefix"]
    }
    logger.info("Start list task")
    while RUN_LOOP == True:
        result = list_bucket(bucket_obj)

        if "token" in result.keys():
            token = result.get("token")
            if token != "":
                bucket_obj["token"] = token
            else:
                RUN_LOOP = False


def submit_list_task(task: dict):
    RUN_LOOP = True
    bucket_obj = {
        "bucket": task["bucket"],
        "prefix": task["prefix"]
    }
    logger.info("Start list task")
    while RUN_LOOP == True:
        result = list_bucket(bucket_obj)

        if "token" in result.keys():
            token = result.get("token")
            if token != "":
                bucket_obj["token"] = token
            else:
                RUN_LOOP = False
