#!/bin/bash

IMAGE_ID=$1
ACCOUNT_ID=$2

aws ec2 modify-image-attribute \
    --image-id ${IMAGE_ID} \
    --launch-permission "Add=[{UserId=${ACCOUNT_ID}}]" && echo Success || exit $?
