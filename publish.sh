#!/bin/bash

# Get the current folder name
packageName=$(basename "$PWD")

# Parse command line arguments
VERBOSE=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -Verbose)
            VERBOSE=true
            shift
            ;;
        -Force)
            FORCE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

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

# if the dist folder is empty, return with error "No distribution files found. Run 'uv build' to create them."
if [ ! -d "./dist" ] || [ -z "$(find ./dist -name "*.whl" -o -name "*.tar.gz" | head -1)" ]; then
    echo "No distribution files found. Run 'uv build' to create them."
    exit 1
fi

packageData=$(uv version --output-format json)
name=$(echo "$packageData" | jq -r '.name')
version=$(echo "$packageData" | jq -r '.version')

if [ "$FORCE" = true ]; then
    if [ -n "$name" ] && [ -n "$version" ]; then
        # First search for the component to get its ID
        searchUrl="$NEXUS_SERVER/service/rest/v1/search?repository=pypi-releases&name=$name&version=$version"
        echo "Searching for existing package $name $version in Nexus..."

        # Perform the search with error handling
        if [ "$VERBOSE" = true ]; then
            searchData=$(curl -v -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" "$searchUrl")
        else
            searchData=$(curl -s -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" "$searchUrl")
        fi
        curl_exit_code=$?

        if [ $curl_exit_code -ne 0 ]; then
            echo "Failed to search for existing package: HTTP error (curl exit code: $curl_exit_code)"
            echo "Cannot determine if package exists for force delete."
        else
            # Extract component ID with error handling
            componentId=$(echo "$searchData" | jq -r '.items[0].id' 2>/dev/null)
            jq_exit_code=$?

            if [ $jq_exit_code -ne 0 ]; then
                echo "Failed to search for existing package: JSON parse error (jq exit code: $jq_exit_code)"
                echo "Response: $searchData"
                echo "Cannot determine if package exists for force delete."
            elif [ -n "$componentId" ] && [ "$componentId" != "null" ]; then
                deleteUrl="$NEXUS_SERVER/service/rest/v1/components/$componentId"

                echo "Force deleting existing package $name $version (ID: $componentId) from Nexus..."
                # Try the delete with the same auth
                if [ "$VERBOSE" = true ]; then
                    curl -X DELETE -v -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" "$deleteUrl" -s -o /dev/null -w "%{http_code}" > /tmp/curl_status
                else
                    curl -X DELETE -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" "$deleteUrl" -s -o /dev/null -w "%{http_code}" > /tmp/curl_status
                fi
                delete_status=$(cat /tmp/curl_status)

                if [ "$delete_status" -ge 200 ] && [ "$delete_status" -lt 300 ]; then
                    echo "Deleted existing package."
                else
                    echo "API Delete failed: $delete_status"
                    echo "Request URL: $deleteUrl"
                    echo "Continuing with publish anyway..."
                fi
            else
                echo "Package $name $version not found in Nexus - nothing to delete."
            fi
        fi
    else
        echo "Could not get name/version from uv for force delete."
    fi
fi

# Publish the package to PyPI repository
uv publish --config-file ../uv.toml
