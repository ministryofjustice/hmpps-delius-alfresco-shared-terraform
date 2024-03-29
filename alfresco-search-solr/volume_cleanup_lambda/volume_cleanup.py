#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os

import json
import boto3
from datetime import datetime, timedelta, timezone

client = boto3.client('ec2')

def handler(event, context):
    n_days_ago = datetime.now(timezone.utc) - timedelta(days=int(os.getenv("DAYS_LIMIT")))
    volume_response = client.describe_volumes(
        Filters=[
            {
                'Name': 'tag:Name',
                'Values': [
                    'ecs-alfresco-search-solr-task-definition*-alfresco-search-solr-cache-vol-*'
                ]
            },
            {
                'Name': 'status',
                'Values': [
                    'available'
                ]
            },
        ]
    )

    volumes_to_delete = [ volume for volume in volume_response['Volumes'] if volume['CreateTime'] <= n_days_ago ]

    for volume in volumes_to_delete:
        print("Deleting volume: ", volume['VolumeId'])
        client.delete_volume(VolumeId=volume['VolumeId'])
    
    print("Search solr EBS volumes cleanup has been completed")

    return {
        'statusCode': 200,
        'body': json.dumps('Search solr EBS volumes cleanup has been completed')
    }


if __name__ == "__main__":
    handler(None, None)
