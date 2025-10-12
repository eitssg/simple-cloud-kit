#!/bin/bash

# define a list of folders to iterate over
folders=(
    "sck-core-ai"
    "sck-core-api" 
    "sck-core-cli" 
    "sck-core-codecommit"
    "sck-core-component" 
    "sck-core-db" 
    "sck-core-deployspec" 
    "sck-core-docker" 
    "sck-core-docker-base"
    "sck-core-docker-server"
    "sck-core-docs" 
    "sck-core-execute" 
    "sck-core-framework" 
    "sck-core-invoker" 
    "sck-core-organization" 
    "sck-core-report"
    "sck-core-runner"
    "sck-core-ui"
)

# iterate over the folders. For each folder:
for folder in "${folders[@]}"; do

    currentFolder=$(pwd)

    # change to the folder
    cd "$folder"

    # get the current folder name
    packageName=$(basename "$PWD")

    # get the version from the pyproject.toml file
    version=$(uv version --short)

    # write the project name and version
    echo "Checking project: $packageName v${version}"

    git pull

    # all all outsdated changes
    git add --all

    # commit the changes with message "Stat changes to version to v{version}"
    git commit -m "Stat changes to version v${version}"

    # push the tag to the remote repository
    git push

    # change back to the parent folder
    cd "$currentFolder"
done