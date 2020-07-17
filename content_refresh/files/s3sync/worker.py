# worker.py

import redis
from rq import Worker, Queue, Connection

from app.config import Config
from app.clients import _redis_conn

conn = _redis_conn()

listen = ['high', 'default', 'low']

if __name__ == '__main__':
    with Connection(conn):
        worker = Worker(map(Queue, listen))
        worker.work()
