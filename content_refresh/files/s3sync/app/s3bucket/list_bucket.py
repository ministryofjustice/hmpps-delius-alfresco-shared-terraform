import boto3
import json


from app.config import Config
from app.clients import _s3_client  # , _redis_conn
from app.helpers.logger import log_handler

# Constants

DEBUG = False
# Should be a power of two since it may get divided by two a couple of times.
MAX_KEYS = 1024
# Max. result size: https://docs.aws.amazon.com/step-functions/latest/dg/service-limits.html
MAX_DATA_SIZE = 131072
SAFETY_MARGIN = 10.0  # Percent
MAX_RESULT_LENGTH = int(MAX_DATA_SIZE * (1.0 - (SAFETY_MARGIN / 100.0)))
PREFIX = ''  # Copy objects based on a provided prefix e.g. '/images/'
START_AFTER = ''  # List objects after a specific key e.g. '/images/1000'


# Globals

logger = log_handler()
# conn = _redis_conn()


# Functions

def handler(bucket_dict):
    assert(isinstance(bucket_dict, dict))
    print(bucket_dict)

    bucket = bucket_dict['bucket']

    region = Config.region

    token = bucket_dict.get('token', '')
    max_keys = bucket_dict.get('maxKeys', MAX_KEYS)
    prefix = bucket_dict.get('prefix', PREFIX)
    start_after = bucket_dict.get('startAfter', START_AFTER)

    args = {
        'Bucket': bucket,
        'MaxKeys': max_keys,
        'Prefix': prefix,
        'StartAfter': start_after
    }

    result = {}
    # s3 = boto3.client('s3', region_name=region)
    s3 = _s3_client()

    while True:
        logger_message = {
            "message": "Listing contents of bucket",
            "bucket": bucket,
            "region": region
        }

        if token is not None and token != '':
            logger_message["continuation token"] = token
            args["ContinuationToken"] = token

        logger_message["max_keys"] = str(max_keys)

        logger.info(logger_message)

        response = s3.list_objects_v2(**args)

        keys = [k['Key'] for k in response.get('Contents', [])]

        logger.info(f"Got {str(len(keys))} result keys.")

        result['keys'] = keys

        result['token'] = response.get('NextContinuationToken', '')
        result_length = len(json.dumps(result))
        if result_length <= MAX_RESULT_LENGTH:
            # try:
            #     logger.info(
            #         f"Adding bucket object keys to redis list: {bucket}"
            #     )
            #     for bkey in result['keys']:
            #         conn.lpush(str(bucket), str(bkey))
            # except Exception as err:
            #     logger.error(
            #         f"Error adding bucket object keys to redis list: {bucket}, error: {str(err)}"
            #     )
            return result
        else:
            # Try again with a smaller may_keys size.
            logger.warning(
                f"Result size: {str(result_length)} is larger than maximum of: {str(MAX_RESULT_LENGTH)}."
            )

            # ask for half the number of keys we got.
            max_keys = int(len(keys) / 2)
            if max_keys == 0:
                raise Exception(
                    'Something is wrong: Downsized max_keys all the way to 0 ...')
            args['MaxKeys'] = max_keys
            logger.info(f"Trying again with max_keys value: {str(max_keys)}")
