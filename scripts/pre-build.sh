#!/usr/bin/env bash

set -e

echo "WORKDIR: ${CODEBUILD_SRC_DIR}"

if [ -z "${PRE_BUILD_ACTION}" ]
then
    echo "--> No pre build args provided, skipping execution"
else
    echo "PRE BUILD ARG PROVIDED: ${PRE_BUILD_ACTION}"
    make ${PRE_BUILD_ACTION} component=${PRE_BUILD_TARGET}
fi
