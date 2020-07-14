# content_refresh/files/s3sync/app/docker/__init__.py

import os

from rq import Queue
from app.clients import docker_client
from app.helpers.logger import log_handler
from app.config import Config
from app.clients import _redis_conn

conn = _redis_conn()

q = Queue(connection=conn)

logger = log_handler()

client = docker_client()


def run_sync_task(task_dict: dict):
    try:
        image_id = Config.task_docker_image
        _env_vars = {
            "SRC_BUCKET": task_dict["source"],
            "DST_BUCKET": task_dict["destination"],
            "TASK_PREFIX": task_dict["prefix"]
        }
        logger.info({
            "message": "environment vars",
            "vars": _env_vars
        })
        result = client.containers.run(
            image_id,
            detach=False,
            environment=_env_vars
        )
        if result:
            logger.info({
                "message": "sync task started",
                "status": result.status,
                "id": result.id
            })
        return True
    except Exception as err:
        logger.error({
            "message": "Error raised starting sync task",
            "error": str(err),
            "prefix": task_dict["prefix"]
        })
        task_dict = {
            "source": task_dict["source"],
            "destination": task_dict["destination"],
            "prefix": task_dict["prefix"]
        }
        task_dict["prefix"] = task_dict
        result = q.enqueue(run_sync_task, task_dict)
        logger.info({
            "message": "sync task resubmitted",
            "id": result
        })
    return False

def update_task_status(es_task_ttl:int):
    hash_name = "active_tasks"
    key_name = os.environ.get("ES_DOCKER_HOST") or "worker"
    ttl = int(es_task_ttl) - 5
    containers = client.containers.list()
    tasks = [x.short_id for x in containers if "worker" not in x.name]
    size = len(tasks)
    if size > 0:
        result = conn.hset(hash_name, key_name, size)
        conn.expire(hash_name, ttl)
        logger.info({
            "message": "sync tasks active",
            "tasks": size,
            "updated": result
        })
        return False
    
    logger.info({
        "message": "No sync task found",
        "tasks": size
    })
    return True
