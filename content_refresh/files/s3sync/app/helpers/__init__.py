# app/helpers/__init__.py

import datetime


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
            for day in range(1, 32):
                task.append(f"{year}/{mth}/{day}")
                task.append(f"contentstore/{year}/{mth}/{day}")
    return task
