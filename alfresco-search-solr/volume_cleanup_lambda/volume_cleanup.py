#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import boto3
from datetime import datetime, timedelta

client = boto3.client('ec2')

def handler(event, context):
    three_days_ago = datetime.now() - timedelta(days=3)
    timestamp_format = '%Y-%m-%dT%H:%M:%S.%fZ'
    creation_date_filter = three_days_ago.strftime(timestamp_format)
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
            {
                'Name': 'create-time',
                'Values': ["<="+creation_date_filter]
            }
        ]
    )


    for volume in volume_response['Volumes']:
        print("Deleting volume: ", volume['VolumeId'])
        client.delete_volume(VolumeId=volume['VolumeId'], DryRun=True)
    
    print("Search solr EBS volumes cleanup has been completed")

    return {
        'statusCode': 200,
        'body': json.dumps('Search solr EBS volumes cleanup has been completed')
    }


if __name__ == "__main__":
    handler(None, None)
