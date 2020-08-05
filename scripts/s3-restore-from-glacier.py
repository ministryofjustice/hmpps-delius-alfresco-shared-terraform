import boto3
import botocore
import os
import time
import sys

region = 'eu-west-2'
aws_profile_name = 'hmpps-token'
aws_role_arn = "arn:aws:iam::050243167760:role/terraform"

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

s3 = boto3.client(
    's3',
    region_name=region,
    aws_access_key_id=access_key_id,
    aws_secret_access_key=secret_access_key,
    aws_session_token=session_token,
)

# Methods


def restore_from_glacier(bucket_name: str, object_key: str, job_tier=None):
    try:
        if job_tier is None:
            job_tier = "Expedited"
        response = s3.restore_object(
            Bucket=bucket_name,
            Key=object_key,
            RestoreRequest={
                "Days": 1,
                "GlacierJobParameters": {
                    "Tier": job_tier,
                }
            }
        )
    except Exception as err:
        print(f"An error was raised submitting restore task, error: {err}")
        return sys.exit(1)


def list_object_versions(bucket_name: str, object_key: str):
    try:
        result = s3.list_object_versions(
            Bucket=bucket_name,
            Prefix=object_key
        )
        return result
    except Exception as err:
        print(f"An error was raised listing versions, error: {err}")
        return sys.exit(1)


def check_restore_status(bucket_name: str, object_key: str):
    try:
        result = result = s3.head_object(
            Bucket=bucket_name,
            Key=object_key
        )
        if 'ongoing-request="false"' in result['Restore']:
            return False

        if 'ongoing-request="true"' in result['Restore']:
            return True
    except Exception as err:
        print(f"An error was raised checking status, error: {err}")
        return sys.exit(1)


def copy_s3_object(bucket_name: str, object_key: str):
    try:
        result = s3.copy_object(
            Bucket=bucket_name,
            CopySource=f"{bucket_name}/{object_key}",
            Key=object_key,
            StorageClass="STANDARD"
        )
    except Exception as err:
        print(f"An error was raised copy object, error: {err}")
    return result


def main_handler(event, context):
    S3_BUCKET_NAME = os.environ.get(
        "S3_BUCKET_NAME ") or "tf-eu-west-2-hmpps-delius-prod-alfresco-storage-s3bucket"
    S3_OBJECT_KEY = os.environ.get(
        "S3_OBJECT_KEY") or "contentstore/2019/6/27/14/29/50019c2f-7215-4e3b-a0be-6033c92fb85c.bin"
    WAIT_FOR_RESTORE_TASK = True
    WAIT_INTERVAL = 20

    object_versions = list_object_versions(
        S3_BUCKET_NAME, S3_OBJECT_KEY)

    if "DeleteMarkers" in object_versions:
        version_id = object_versions["DeleteMarkers"][0]["VersionId"]
        result = s3.delete_object(
            Bucket=S3_BUCKET_NAME,
            Key=S3_OBJECT_KEY,
            VersionId=version_id
        )
        print(result)
        print(f"Deleted marker version {version_id}")

    restore_from_glacier(S3_BUCKET_NAME, S3_OBJECT_KEY)

    while WAIT_FOR_RESTORE_TASK == True:
        restore_in_progress = check_restore_status(
            S3_BUCKET_NAME, S3_OBJECT_KEY)
        if restore_in_progress == False:
            print(
                f"Restore for object s3: // {S3_BUCKET_NAME}/{S3_OBJECT_KEY} task complete.")
            result = copy_s3_object(S3_BUCKET_NAME, S3_OBJECT_KEY)
            print(result)
            WAIT_FOR_RESTORE_TASK = restore_in_progress
            break
        else:
            print(
                f"Restore for object s3://{S3_BUCKET_NAME}/{S3_OBJECT_KEY} in progress. Please wait!")
            time.sleep(WAIT_INTERVAL)


if __name__ == "__main__":
    main_handler(event={}, context={})
