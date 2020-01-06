from pythonjsonlogger import jsonlogger
from app.config import Config
import logging


def get_logger():
    logger = logging.getLogger(__name__)
    log_level = Config.log_level
    logger.setLevel(logging.getLevelName(log_level.upper()))

    if not logger.handlers:
        logHandler = logging.StreamHandler()
        formatter = jsonlogger.JsonFormatter()
        logHandler.setFormatter(formatter)
        logger.addHandler(logHandler)
    return logger
