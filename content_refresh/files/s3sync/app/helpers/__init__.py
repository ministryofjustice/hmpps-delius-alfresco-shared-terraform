# app/helpers/__init__.py

import datetime

from app.config import Config
from app.clients import _redis_conn


def _get_year_list():
    now = datetime.datetime.now()
    start_year = 2016
    end_year = now.year + 1
    _list = [x for x in range(start_year, end_year, 1)]
    return _list


def generate_task_list():
    years = _get_year_list()
    months = range(1, 13, 1)
    task = []
    for year in years:
        for mth in months:
            task.append(f"{year}/{mth}")
            task.append(f"contentstore/{year}/{mth}/")
    return task


def save_to_redis(task_type: str, keys: list):
    try:
        for item in keys:
            conn = _redis_conn()
            _ttl = Config.redis_ttl
            _object_name = f"{task_type}:{item}"
            resp = conn.set(_object_name, "false", _ttl)
            if resp == True:
                print(
                    f"Added object {_object_name} to redis")
            return resp
    except Exception as err:
        print({
            "message": f"Error adding object {_object_name} to redis",
            "error": str(err)
        })
        return None
