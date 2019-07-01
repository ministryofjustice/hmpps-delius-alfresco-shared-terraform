import boto3

region = 'eu-west-2'
aws_profile_name = 'hmpps-token'
aws_role_arn = 'arn:aws:iam::563502482979:role/admin'

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

elb = boto3.client(
    'elb',
    region_name=region,
    aws_access_key_id=access_key_id,
    aws_secret_access_key=secret_access_key,
    aws_session_token=session_token,
)
asg = boto3.client(
    'autoscaling',
    region_name=region,
    aws_access_key_id=access_key_id,
    aws_secret_access_key=secret_access_key,
    aws_session_token=session_token,
)
