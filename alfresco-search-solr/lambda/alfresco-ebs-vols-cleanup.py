import json
import botocore
import boto3
import os
import time
from datetime import datetime

client = boto3.client('ec2')
ec2 = boto3.resource('ec2')

# Function to filter and return all EBS volumes whose Name tags start with the same prefix
def filter_vols_tag(key, value):
    nr = 0
    volumes = ec2.volumes.all() 
    totalVols = []

    for volume in volumes:
        if volume.tags != None:
            for tag in volume.tags:
                if tag['Key'] == key:
                    name = tag['Value']
                    if name.startswith(value):
                        totalVols.append(volume.id)
                        nr = nr + 1
    
    return totalVols


# Function to filter and return all EBS volumes which are the same status (which are either unattached or attached to any ec2 instance)
def filter_vols_status(status):
    client = boto3.client('ec2')
    custom_filter_vols_by_status = [
        {
            'Name': 'status',
            'Values': [status]
        }
    ]
    totalVols= []
    nr = 0
    response = client.describe_volumes(Filters=custom_filter_vols_by_status)
    volume_full_details = response['Volumes']

    for volume_detail in volume_full_details:
            volume_id = volume_detail['VolumeId']
            nr = nr + 1
            totalVols.append(volume_id)
    
    return totalVols


# Function to filter and return all EBS volumes older than x days (e.g. x = 3 -> return all volumes 3 days or older)
def filter_vols_by_date(mydate, days_limit):
    x = 0
    volumes = ec2.volumes.all() 
    name = ''
    totalVols = []
    days_old = 0

    for volume in volumes:
        time = volume.create_time
        days_old = mydate.date() - time.date()
        if (days_old.days >= days_limit):
            totalVols.append(volume.id)
            x = x + 1
    
    return totalVols


# Main lambda handler function
def handler(event, context):
    
    # Get solr cache volumes which has the following prefix: 'ecs-alfresco-search-solr-task-definition (-*-alfresco-search-solr-cache-vol')
    x = "Name"
    y = "ecs-alfresco-search-solr-task-definition"
    solrCacheVols = filter_vols_tag(x,y)
    print("The following volumes are search solr cache volumes: ", solrCacheVols)
    print(".....")
    
    # Get unattached volumes 
    unattachedVols = filter_vols_status('available')
    print("The following volumes are unattached volumes: ", unattachedVols)
    print(".....")
    
    # Get volumes older than 3 days in in current environment
    date = datetime.now()
    olderVols = filter_vols_by_date(date, 3)
    print("The following volumes are volumes created at least 3 days ago: ", olderVols)
    print(".....")
    
    # Remove search solr cache EBS volumes at least 3 days old:
    if solrCacheVols:
        for vol in solrCacheVols:
            for i in unattachedVols:
                for j in olderVols:
                    if vol == i and vol == j:
                        #client.delete_volume(VolumeId=vol)
                        #print("The following volume has been removed: ", vol)
                        print("The following volume should be removed: ", vol)
    else:
        print("There are no search solr cache volumes: ")
    
    print("........")
    
    #######################    
    # TEST Remove volumes 
    #testVols = filter_vols_tag("Name", "test-vol-test")
    #unattachedVols = filter_vols_status('available')
    #if testVols:
    #    for vol in testVols:
    #        for i in unattachedVols:
    #            if vol == i:
    #                client.delete_volume(VolumeId=vol)
    #                print("The following volume has been removed: ", vol)
    #else:
    #    print("There are no volumes to be removed")
  
    return {
        'statusCode': 200,
        'body': json.dumps('Search solr EBS volumes cleanup has been completed')
    }
