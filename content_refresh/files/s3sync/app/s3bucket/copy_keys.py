import logging
from uuid import uuid4
from threading import Thread
from botocore.exceptions import ClientError
import queue
import json
import time

from app.config import Config
from app.clients import _s3_client
from app.helpers.logger import log_handler

# Constants

DEBUG = False
# Empirical value for now. Should find good way to measure/auto-scale this.
THREAD_PARALLELISM = 10
METADATA_KEYS = [
    'CacheControl',
    'ContentDisposition',
    'ContentEncoding',
    'ContentLanguage',
    'ContentType',
    'Expires',
    'Metadata'
]


# Globals

logger = log_handler()

# Utility functions


def collect_metadata(response):
    metadata = {}
    for key in METADATA_KEYS:
        if key in response:
            metadata[key] = response[key]
    metadata_json = json.dumps(metadata, sort_keys=True, default=str)
    return metadata_json


# Classes

class KeySynchronizer(Thread):
    def __init__(self, job_queue=None, source=None, destination=None, region=None):
        super(KeySynchronizer, self).__init__()
        self.job_queue = job_queue
        self.source = source
        self.destination = destination
        self.s3 = _s3_client()

    def copy_redirect(self, key, target):
        logger.info(
            f"Copying redirect: {key} from bucket: {self.source} to destination bucket: {self.destination}"
        )
        self.s3.put_object(
            Bucket=self.destination,
            Key=key,
            WebsiteRedirectLocation=target
        )

    def copy_object(self, key):
        logger.info(
            f"Copying key: {key} from bucket: {self.source} to destination bucket: {self.destination}"
        )
        print(
            f"Copying key: {key} from bucket: {self.source} to destination bucket: {self.destination}")
        self.s3.copy_object(
            CopySource={
                'Bucket': self.source,
                'Key': key
            },
            Bucket=self.destination,
            Key=key,
            MetadataDirective='COPY',
            TaggingDirective='COPY'
        )

    def run(self):
        while not self.job_queue.empty():
            try:
                key = self.job_queue.get(True, 1)
            except Empty:
                return

            source_response = self.s3.head_object(Bucket=self.source, Key=key)

            try:
                destination_response = self.s3.head_object(
                    Bucket=self.destination, Key=key)
            except ClientError as e:
                # 404 = we need to copy this.
                if int(e.response['Error']['Code']) == 404:
                    if 'WebsiteRedirectLocation' in source_response:
                        self.copy_redirect(
                            key, source_response['WebsiteRedirectLocation'])
                    else:
                        self.copy_object(key)
                    continue
                elif int(e.response['Error']['Code']) == 503:
                    logger.info("Too many requests")
                    time.sleep(1)
                    logger.info(f"Retrying copy key task {key}")
                    self.copy_object(key)
                else:  # All other return codes are unexpected.
                    raise e

            if 'WebsiteRedirectLocation' in source_response:
                if (
                    source_response['WebsiteRedirectLocation'] !=
                    destination_response.get('WebsiteRedirectLocation', None)
                ):
                    self.copy_redirect(
                        key, source_response['WebsiteRedirectLocation'])
                continue

            source_etag = source_response.get('ETag', None)
            destination_etag = destination_response.get('ETag', None)
            if source_etag != destination_etag:
                self.copy_object(key)
                continue

            source_metadata = collect_metadata(source_response)
            destination_metadata = collect_metadata(destination_response)
            if source_metadata == destination_metadata:
                logger.info(
                    f"Key {key} from bucket {self.source} is already current in destination bucket {self.destination}"
                )
                continue
            else:
                self.copy_object(key)


# Functions

def sync_keys(source=None, destination=None, region=None, keys=None):
    job_queue = queue.SimpleQueue()
    worker_threads = []

    for i in range(THREAD_PARALLELISM):
        worker_threads.append(KeySynchronizer(
            job_queue=job_queue,
            source=source,
            destination=destination,
            region=region,
        ))

    for key in keys:
        logger.info(f"Queuing: {key} for synchronization.")
        job_queue.put(key)

    logger.info(
        f"Starting  {str(THREAD_PARALLELISM)} key synchronization processes for buckets: {source} and {destination}"
    )
    for t in worker_threads:
        t.start()

    for t in worker_threads:
        t.join()


def handler(task_obj):
    assert(isinstance(task_obj, dict))

    source = task_obj['source']
    destination = task_obj['destination']
    keys = task_obj['keys']

    region = Config.region

    logger.info(
        f"Copying {str(len(keys))} keys from bucket {source} to bucket: {destination}"
    )

    sync_keys(source=source, destination=destination, keys=keys, region=region)

    return None
