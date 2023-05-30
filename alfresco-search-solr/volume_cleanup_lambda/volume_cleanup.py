#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import boto3
from datetime import datetime, timedelta, timezone

client = boto3.client('ec2')

def handler(event, context):
    three_days_ago = datetime.now(timezone.utc) - timedelta(days=3)
    volume_response = client.describe_volumes(
        Filters=[
            {
                'Name': 'tag:Name',
                'Values': [
                    'ecs-alfresco-search-solr-task-definition*'
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

    volumes_to_delete = [ volume for volume in volume_response['Volumes'] if volume['CreateTime'] <= three_days_ago ]

    for volume in volumes_to_delete:
        print("Deleting volume: ", volume['VolumeId'])
        client.delete_volume(VolumeId=volume['VolumeId'], DryRun=True)
    
    print("Search solr EBS volumes cleanup has been completed")

    return {
        'statusCode': 200,
        'body': json.dumps('Search solr EBS volumes cleanup has been completed')
    }


if __name__ == "__main__":
    handler(None, None)
