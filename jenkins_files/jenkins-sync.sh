i#!/bin/sh

set -e

pwd

# set region
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')

repo=hmpps-delius-alfresco-shared-terraform

rm -rf ${repo}

git clone https://github.com/ministryofjustice/${repo}.git --branch issue-75-add-restore-docs

docker run --rm -e GIT_BRANCH=master -v $(pwd)/${repo}:/home/tools/data \
  -v ${HOME}/.aws:/home/tools/.aws mojdigitalstudio/hmpps-terraform-builder sh scripts/s3_copy_contents.sh \
  ${environment_name} master https://github.com/ministryofjustice/hmpps-env-configs.git ${REGION}