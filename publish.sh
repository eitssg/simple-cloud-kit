#!/bin/bash

# Get the current folder name
packageName=$(basename "$PWD")

# if the environment variable NEXUS_SERVER is not set, return with error "NEXUS_SERVER environment variable not set"
if [ -z "$NEXUS_SERVER" ] || [ -z "$NEXUS_USERNAME" ] || [ -z "$NEXUS_PASSWORD" ]; then
    echo "Error while PUBLISHING: NEXUS_SERVER environment variables are not set"
    exit 1
fi

echo -e "\n---- PUBLISHING project: $packageName to $NEXUS_SERVER/repository/pypi-releases/"

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if [ ! -f "./pyproject.toml" ]; then
    echo "Must be in project folder"
    exit 1
fi

# Set the URL for the nexus-releases repository
poetry config repositories.nexus-releases "$NEXUS_SERVER/repository/pypi-releases/"

# Publish the package to PyPI repository
poetry publish --repository nexus-releases -u "$NEXUS_USERNAME" -p "$NEXUS_PASSWORD"
