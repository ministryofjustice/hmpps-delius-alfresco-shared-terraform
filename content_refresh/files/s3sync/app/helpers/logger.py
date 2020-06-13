# s3sync/app/helpers/logger.py

import logging


def log_handler():
    service_name = "refreshTasks"
    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s %(name)s %(levelname)s:%(message)s")
    logger = logging.getLogger(service_name)
    return logger
