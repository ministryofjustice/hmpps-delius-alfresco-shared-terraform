#!/bin/bash

build_dir="/opt/data/build"
rm -rf package
pip install -r build/requirements.txt -t ./package && echo Success || exit $?
cd package
zip -r9 ${build_dir}/function.zip . && echo Success || exit $?
cd ${build_dir}
zip -g function.zip *.py && echo Success || exit $?
zip -r function.zip app/* && echo Success || exit $?
echo "build complete"
