#!/bin/bash

# if python cannot be found, exit
if ! command -v python &> /dev/null; then
    echo "Python could not be found"
    exit 1
fi

# Get the name of the current folder
packageName=$(basename "$PWD")

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if [ ! -f "./pyproject.toml" ]; then
    echo "Must be in project folder"
    exit 1
fi

if [ ! -d ".venv" ]; then
   echo "Creating virtualenv"
   python -m venv .venv
   source .venv/bin/activate
   python -m pip install -q --upgrade pip
   python -m pip install -q poetry poetry-dynamic-versioning polib
else
   source .venv/bin/activate
fi

# if not in virtual environment exit
if [ -z "$VIRTUAL_ENV" ]; then
   echo "Not in virtual environment"
   exit 1
fi


echo "---- Python version and source folder"
python -V
which python

# Check if poetry is installed
if ! command -v poetry &> /dev/null; then
    echo "Poetry is not installed. Installing it."
   python -m pip install -q poetry poetry-dynamic-versioning polib
fi

# Get the current version of the poetry version -s command
version=$(poetry version -s)

echo "\n---- PACKAGING project: $packageName v$version for Lambda ----"

# If the dist folder doesn't exist, exit
if [ ! -d "dist" ]; then
    echo "Dist folder does not exist. You must build the project first."
    exit 1
fi

# Remove the package folder if it exists
if [ -d "package" ]; then
    rm -rf "package"
fi

echo "Packaging Lambda $packageName"

# Get the current version of poetry version -s command
version=$(poetry version -s)

# Package Name
artefactName="$packageName-$version.zip"

# Remove the artefact by packageName
rm -f "${packageName}*.zip"

# Find the .whl file in the dist folder
whlFile=$(find dist -name "*.whl" | head -n 1)

if [ -z "$whlFile" ]; then
    echo "No .whl file found in the dist folder."
    return 0
fi

echo "Installing $whlFile into the package folder"
pip install --upgrade -t package "$whlFile"

if [ -d "package" ]; then
    cd package
    # brew install p7zip
    7z a -bd -bb0 "../$artefactName" . -xr"!*.pyc" > /dev/null 2>&1
    cd ..
    rm -rf "package"

    echo "Package created successfully: $artefactName"

    destinationFolder="../sck-core-docker/lambda"
    if [ ! -d "$destinationFolder" ]; then
        mkdir -p "$destinationFolder"
    fi

    # if any file begins with the prefix $packageName and ends with .zip, remove it
    existingFiles=$(find "$destinationFolder" -name "$packageName*.zip")
    if [ ! -z "$existingFiles" ]; then
        rm -f $existingFiles
    fi

    # Move the artefact to the destination folder
    mv "$artefactName" "$destinationFolder"
    echo "Package moved to: $destinationFolder"
    echo "Package creation completed successfully."
else
    echo "Package creation failed."
    exit 1
fi

# Upload the zip file to the Nexus repsitory /files/sck/
# echo "Uploading artefact to Nexus artefacts repository"
# curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" --upload-file "$artefactName" \
#    "$NEXUS_SERVER/repository/files/sck/$artefactName"

echo "Lambda package: $artefactName"
