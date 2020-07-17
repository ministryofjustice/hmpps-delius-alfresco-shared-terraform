# app/helpers/__init__.py

import datetime


def _get_year_list(now):
    start_year = 2016
    end_year = now.year + 1
    _list = [x for x in range(start_year, end_year, 1)]
    return _list


def generate_task_list():
    now = datetime.datetime.now()
    years = _get_year_list(now)
    task = []
    for year in years:
        mnth_start = 1
        mnth_end = 12
        if year == 2016:
            mnth_start = 6
        if year == now.year:
            mnth_end = now.month

        months = range(mnth_start, mnth_end + 1, 1)
        for mth in months:
            for day in range(1, 32):
                task.append(f"{year}/{mth}/{day}")
                task.append(f"contentstore/{year}/{mth}/{day}")
    return task
