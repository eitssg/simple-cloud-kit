#!/bin/bash

# Exit if the python command cannot be found
if ! command -v python &> /dev/null; then
    echo "Python could not be found"
    exit 1
fi

# Get the current folder name
packageName=$(basename "$PWD")

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if [ ! -f "./pyproject.toml" ]; then
    echo "Must be in project folder"
    exit 1
fi

# if the .venv folder does not exist, create it
if [ ! -d ".venv" ]; then
    python -m venv .venv
    source .venv/bin/activate
    python -m pip install --upgrade pip
    python -m pip install --upgrade poetry poetry-dynamic-versioning polib
else
    source .venv/bin/activate
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

# Check if poetry is installed
if ! command -v poetry &> /dev/null; then
    echo "Poetry is not installed.  Installing it."
    python -m pip install -q poetry poetry-dynamic-versioning polib
fi

version=$(poetry version | awk '{print $2}')

echo -e "\n---- BUILDING project: $packageName v${version}"

# Remove the dist folder if it exists
if [ -d "dist" ]; then
    rm -rf "dist"
fi

# Remove the build folder if it exists
if [ -d "build" ]; then
    rm -rf "build"
fi

# You might ask why I'm running "poetry-dynamic-versioning".  Well, for some reason, the versioning is not working
# as expected with 'poetry build' and the version number is not being updated in the files indicated in the
# pyproject.toml file replacements section.
# But, I found that manually running the "poetry-dynamic-versioning" command will update the version number in the files.
# (my setup seems to be 'non-standard' and I'm not sure why it's not working as expected)
poetry-dynamic-versioning

echo -e "\n---- Installing the project and depndencies using Poetry"

# remove all the *.egg-info folders and poetry lock
rm -f poetry.lock
rm -rf *.egg-info

# Install project dependencies
poetry install

echo -e "\n---- Building the distribution files for project: $packageName v${version}"

distPath="../sck-core-docker/dist"
mkdir -p "$distPath"

filePrefix=$(echo "$packageName" | sed 's/-/_/g')

# if the dist folder contains files with the project prefix remove them
rm -f "$distPath/$filePrefix*"

# Copy the files from the dist folder to the destination folder
cp -r dist/* "$distPath/"

echo -e "\n---- Distribution files copied to $distPath"
echo -e "\n---- Build complete for project: $packageName v${version}"

# if the file .lambda exists then execute package.ps1 script
if [ -f ".lambda" ]; then
    . ../package.ps1
fi