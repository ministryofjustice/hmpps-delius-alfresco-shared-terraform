# content_refresh/files/s3sync/app/docker/__init__.py

import os


from rq.registry import FailedJobRegistry
from rq import Queue, get_current_job
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
        job_id = get_current_job()
        _env_vars = {
            "SRC_BUCKET": task_dict["source"],
            "DST_BUCKET": task_dict["destination"],
            "TASK_PREFIX": task_dict["prefix"]
        }
        logger.info({
            "message": "environment vars",
            "vars": _env_vars,
            "job_id": job_id
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
        result = q.enqueue(run_sync_task, task_dict, job_timeout=3600)
        logger.info({
            "message": "sync task resubmitted",
            "id": result
        })
    return False


def update_task_status(es_task_ttl: int):
    hash_name = "active_tasks"
    key_name = os.environ.get("ES_DOCKER_HOST") or "worker"
    ttl = int(es_task_ttl) - 5
    containers = client.containers.list()
    tasks = [x.short_id for x in containers if "worker" not in x.name]
    size = len(tasks)
    if size > 0:
        result = conn.hset(hash_name, key_name, size)
        if result:
            requeue_jobs()
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


def requeue_jobs():
    try:
        registry = q.failed_job_registry
        failed_jobs = FailedJobRegistry(queue=q)
        logger.info({
            "message": "Failed jobs",
            "count": len(failed_jobs)
        })
        for job_id in failed_jobs.get_job_ids():
            result = registry.requeue(job_id)
            logger.info({
                "message": "Requeued job",
                "id": job_id
            })
        return True
    except Exception as err:
        logger.error({
            "message": "Error raised requeuing job",
            "error": str(err),
            "id": job_id
        })
        return
