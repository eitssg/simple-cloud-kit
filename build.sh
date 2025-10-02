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

if [ "$NEW" == "1" ]; then
    rm .python-version
    echo "Removing virtual env"
    rm -rf .venv
fi

# if the .venv folder does not exist, create it
if [ ! -d ".venv" ]; then
    python -m venv .venv
fi

source .venv/bin/activate

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

version=$(uv version --short)

echo -e "\n---- BUILDING project: $packageName v${version}"

# Remove the dist folder if it exists
if [ -d "dist" ]; then
    rm -rf "dist"
fi

# Remove the build folder if it exists
if [ -d "build" ]; then
    rm -rf "build"
fi

echo -e "\n---- Installing the project and depndencies using UV"


# Install project dependencies
if [ "$DEV" == "1" ]; then
   echo "Installing with DEVELOPMENT tools"
   uv sync --all-extras
else
   uv sync
fi

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
