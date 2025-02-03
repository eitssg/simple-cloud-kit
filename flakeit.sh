#!/bin/bash

# Get the current folder name
packageName=$(basename "$PWD")

version=$(poetry version -s)

echo -e "\n---- LINTING project: $packageName v${version}"

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if [ ! -f "./pyproject.toml" ]; then
    echo "Must be in project folder"
    exit 1
fi

poetry run black .

poetry run flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
