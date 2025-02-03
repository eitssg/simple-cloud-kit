#!/bin/bash

# Get the current folder name
packageName=$(basename "$PWD")

version=$(poetry version -s)

echo -e "\n---- TESTING project: $packageName v${version}"

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if [ ! -f "./pyproject.toml" ]; then
    echo "Must be in project folder"
    exit 1
fi

# if the .env file does not exist, create it:
if [ ! -f "./.env" ]; then

    echo "Creating .env file"

    # Write the lines to .env
    echo "LOCAL_MODE=True" >> .env
    echo "CLIENT=test-client" >> .env
    echo "DYNAMODB_HOST=http://localhost:8000" >> .env
    echo "VOLUME=$HOME/core" >> .env
    echo "LOG_DIR=$HOME/core/logs" >> .env
    echo "CONSOLE=interactive" >> .env
    echo "LOG_LEVEL=DEBUG" >> .env
fi

poetry run pytest 