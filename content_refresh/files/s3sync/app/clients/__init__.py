# app/clients/__init__py

import boto3
import redis

from app.config import Config

region = Config.region
aws_profile_name = Config.aws_profile
aws_role_arn = Config.aws_role_arn


if aws_profile_name is not None:
    session = boto3.Session(profile_name=aws_profile_name)

    sts_client = session.client('sts')
    assumed_role_object = sts_client.assume_role(
        RoleArn=aws_role_arn,
        RoleSessionName="AssumeRoleSession1"
    )

    credentials = assumed_role_object['Credentials']
    access_key_id = credentials['AccessKeyId']
    secret_access_key = credentials['SecretAccessKey']
    session_token = credentials['SessionToken']

    session = boto3.Session(
        aws_access_key_id=access_key_id,
        aws_secret_access_key=secret_access_key,
        aws_session_token=session_token,
    )


def _s3_client():
    s3 = boto3.client('s3', region_name=region)
    if aws_profile_name is not None:
        s3 = boto3.client(
            's3',
            region_name=region,
            aws_access_key_id=access_key_id,
            aws_secret_access_key=secret_access_key,
            aws_session_token=session_token,
        )
    return s3


def _redis_conn():
    redis_url = Config.redis_url
    conn = redis.from_url(redis_url)
    return conn
