#!/bin/bash

# Get the name of the current folder
packageName=$(basename "$PWD")

version=$(poetry version -s)

echo -e "\n---- PACKAGING project: $packageName v${version} for Lambda"

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if [ ! -f "./pyproject.toml" ]; then
    echo "Must be in project folder"
    exit 1
fi

if [ -z "$VIRTUAL_ENV" ]; then
   echo "Activating vitualenv"
   source .venv/bin/activate
fi

echo "Packaging Lambda $packageName"

# Get the current version of the poetry version -s command
version=$(poetry version -s)

# Package Name
artefactName="$packageName-$version.zip"

# Remove the artefact by packageName
rm -f "${packageName}*.zip"

# Remove the package folder if it exists
if [ -d "package" ]; then
    rm -rf "package"
fi

# Find the .whl file in the dist folder
whlFile=$(find dist -name "*.whl" | head -n 1)

if [ -z "$whlFile" ]; then
    echo "No .whl file found in the dist folder."
    return 0
fi

# Install the .whl file into the package folder
PIP_INDEX_URL=${NEXUS_SERVER}/repository/pypi/simple/ \
   pip -v install --upgrade -t package "$whlFile"

if [ -d "package" ]; then
    cd package
    # brew install p7zip
    7z a -bd -bb0 "../$artefactName" . -xr"!*.pyc" > /dev/null 2>&1
    cd ..
    rm -rf "package"
else
    echo "Package creation failed."
    return 0
fi

# Upload the zip file to the Nexus repsitory /files/sck/
echo "Uploading artefact to Nexus artefacts repository"
curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" --upload-file "$artefactName" \
   "$NEXUS_SERVER/repository/files/sck/$artefactName"

echo "Lambda package: $artefactName"
echo "complete."
