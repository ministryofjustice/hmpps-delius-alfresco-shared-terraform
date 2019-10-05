from pythonjsonlogger import jsonlogger
from functools import wraps
from datetime import datetime, timedelta

import logging
import boto3
import os
import traceback
import time
import math

# ENV VARS
# ARCHIVE_NUMBER_OF_DAYS = number of days to archive
# AWS_REGION = aws region
# ARCHIVE_BUCKET = s3 bucket to archive/export logs to
# LOG_SEARCH_FILTER = filter log groups based on log group name
# WAIT_INTERVAL = interval to wait between task submission, default is 10 seconds

region = os.environ.get('ARCHIVE_REGION', 'eu-west-2')
dest_bucket = os.environ.get('ARCHIVE_BUCKET')
log_search_filter = os.environ.get('LOG_SEARCH_FILTER', '-alf')
wait_interval = int(os.environ.get('WAIT_INTERVAL', 10))

# boto client
logs = boto3.client(
    'logs',
    region_name=region
)

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

if not logger.handlers:
    logHandler = logging.StreamHandler()
    formatter = jsonlogger.JsonFormatter()
    logHandler.setFormatter(formatter)
    logger.addHandler(logHandler)

# log timer
def log_timer(func):

    @wraps(func)
    def wrapper(*args, **kwargs):
        starttime = time.time()
        result = func(*args, **kwargs)
        endtime = time.time()
        duration = endtime - starttime
        logger.info('Function {} execution completed'.format(func.__name__), extra={"duration":duration})
        return result
    return wrapper

# get log groups
@log_timer
def group_names():
    try:
        groupnames = []
        paginator = logs.get_paginator('describe_log_groups')
        response_iterator = paginator.paginate()
        for response in response_iterator:
            listOfResponse=response["logGroups"]
            for result in listOfResponse:
                if log_search_filter in result["logGroupName"]:
                    groupnames.append(result["logGroupName"])
        logger.info("Cloudwatch log-groups found: {}".format(groupnames))
    except:
        logger.error("uncaught exception: %s", traceback.format_exc())
        exit(1)
    return groupnames

# Main function
@log_timer
def lambda_handler(event, context):
    nDays = int(os.environ.get('ARCHIVE_NUMBER_OF_DAYS', 1))
    deletionDate = datetime.now() - timedelta(days=nDays)
    logger.info('Deletion date is {}'.format(deletionDate))
    startOfDay = deletionDate.replace(hour=0, minute=0, second=0, microsecond=0)
    endOfDay = deletionDate.replace(hour=23, minute=59, second=59, microsecond=999999)
    fromTime=math.floor(startOfDay.timestamp() * 1000)
    toTime=math.floor(endOfDay.timestamp() * 1000)
    group_name = group_names()
    if not isinstance(group_name, list):
        logger.error('group_name is not a valid list object')
        exit(1)
        
    if group_name == []:
        logger.warning('No matching groups found, please update the environment variable LOG_SEARCH_FILTER'.format(log_search_filter))
        exit(0)
    
    for group in group_name:
        try:
            logger.info('Creating export task for log group {}'.format(group))
            destination_prefix = group
            if group[:1] == '/':
                destination_prefix = group[1:]
            response = logs.create_export_task(
                taskName='export_task',
                logGroupName=group,
                fromTime=math.floor(startOfDay.timestamp() * 1000), 
                to=math.floor(endOfDay.timestamp() * 1000), 
                destination=dest_bucket,
                destinationPrefix='archived_logs/{}'.format(destination_prefix)
            )
            logger.info(response)
            time.sleep(wait_interval)
        except:
            logger.error("uncaught exception: %s", traceback.format_exc())
            exit(2)
