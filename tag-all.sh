#!/bin/bash

# define an input parameter named "tag" of type string
tag=$1

example="Example: ./tag-all.sh v1.0.0"

# ensure the tag is not empty else fail
if [ -z "$tag" ]; then
    echo "Tag must be provided"
    echo "$example"
    exit 1
fi

# ensure the tag begins with the letter "v" else fail
if [[ ${tag:0:1} != "v" ]]; then
    echo "Tag must begin with 'v'"
    echo "$example"
    exit 1
fi

# check that the string after the v is in the semver format
if [[ ! "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Tag must be in semver format"
    echo "$example"
    exit 1
fi

# define a list of folders to iterate over
folders=("sck-core-api" "sck-core-cli" "sck-core-component" "sck-core-db" "sck-core-deployspec" "sck-core-docker" "sck-core-docs" "sck-core-execute" "sck-core-framework" "sck-core-invoker" "sck-core-runner")

# iterate over the folders. For each folder:
for folder in "${folders[@]}"; do

    currentFolder=$(pwd)

    # change to the folder
    cd "$folder"

    # get the current folder name
    packageName=$(basename "$PWD")

    # get the version from the pyproject.toml file
    version=$(poetry version -s)

    # write the project name and version
    echo "Checking project: $packageName v${version}"

    # Get all the tags in the git repository in the submodule
    tags=$(git tag)

    if [[ "$tags" == *"$tag"* ]]; then
        echo "Tag $tag already exists project $folder"
        # continue to the next folder
        cd "$currentFolder"
        continue
    fi

    # if the tag does not exist, create it
    git tag "$tag"

    # push the tag to the remote repository
    git push origin "$tag"

    # build the project with "../build.sh" command
    ../build.sh

    # change back to the parent folder
    cd "$currentFolder"
done