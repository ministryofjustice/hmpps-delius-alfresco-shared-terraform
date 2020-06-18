# app/config.py

import os


class Config:
    region = os.environ.get("AWS_REGION", "eu-west-2")
    aws_profile = os.environ.get("AWS_PROFILE", None)
    aws_role_arn = os.environ.get(
        "AWS_ROLE_ARN", None)
    source_bucket = os.environ.get(
        "SOURCE_BUCKET", None)
    destination_bucket = os.environ.get(
        "DESTINATION_BUCKET", None)
    redis_url = os.getenv("REDISTOGO_URL", None)
    redis_ttl = int(os.environ.get("REDIS_TTL", 86400))
