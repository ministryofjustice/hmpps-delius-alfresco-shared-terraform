#!/bin/bash

current_dir=$(pwd)

if [ -d "${attributes_dir}" ]; then
    echo "${attributes_dir} found"
else
    echo "${attributes_dir} not found, creating"
    mkdir -p ${attributes_dir}
fi

for dir in ${attributes_list}
do
    if [ -d "${current_dir}/${dir}" ]; then
    # Control will enter here if $DIRECTORY exists.
        mkdir -p ${current_dir}/${inspec_profile}/files
        attrFile="${current_dir}/${inspec_profile}/files/terraform.json"
        rm -rf ${attrFile}
        echo "Getting outputs for: ${dir}"
        cd ${current_dir}/${dir}
        terragrunt output -json >> ${attrFile}
        if [ "$?" -ne "0" ]; then
            echo "Outputs generation failed for ${attrFile}"
            exit 1
        fi
    else
        echo "Directory not found: ${current_dir}/${dir}"
        exit 1
    fi

done

cd ${current_dir}