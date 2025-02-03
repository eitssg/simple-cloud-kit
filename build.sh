#!/bin/bash

# Get the current folder name
packageName=$(basename "$PWD")

version=$(poetry version -s)

echo -e "\n---- BUILDING project: $packageName v${version}"

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if [ ! -f "./pyproject.toml" ]; then
    echo "Must be in project folder"
    exit 1
fi

# Remove the dist folder if it exists
if [ -d "dist" ]; then
    rm -rf "dist"
fi

# check if virtual environment is activated and if not fail with an error
if [ -z "$VIRTUAL_ENV" ]; then
    echo "Virtual environment is not activated. Run 'source .venv/bin/activate' to activate the virtual environment."
    exit 1
fi

# Check if the virtual environment is activated and show only the version and source folder and do not show titles
echo -e "\n---- Python version and source folder"
pythonCommand=$(command -v python)
pythonVersion=$(python --version)
pythonSource=$(dirname "$pythonCommand")
echo "Version: $pythonVersion"
echo "Source: $pythonSource"

echo -e "\n---- Installing/updating dependencies"

python -m pip -q install --upgrade pip
python -m pip -q install --upgrade poetry poetry-dynamic-versioning polib

poetry update
poetry install

echo -e "\n---- Building the project"

# You might ask wky I'm running "poetry-dynamic-versioning".  Well, for some reason, the versioning is not working
# as expected with 'poetry build' and the version number is not being updated in the files indictaed in the 
# pyproject.toml file replacements section.
# But, I found that manually running the "poetry-dynamic-versioning" command will update the version number in the files.
# (my setup seems to be 'non-standard' and I'm not sure why it's not working as expected)
poetry-dynamic-versioning

poetry build

