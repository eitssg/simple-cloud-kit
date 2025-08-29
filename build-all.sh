#!/bin/bash

# if the file build-all.sh does not exist, return with error "Must be in main toolkit folder":
if [ ! -f "./build-all.sh" ]; then
    echo "Must be in main toolkit folder"
    exit 1
fi

# Function to build and package a project
Build_AppComponent() {
    local project=$1

    # Save the original directory
    local mainDir=$(pwd)

    # Return if the project path cannot be found
    if [ ! -d "$project" ]; then
        echo "Project $project does not exist"
        return
    fi

    # Change to the sub-project folder
    cd "$project"

    echo -e "\n\n--------------------------------------------"
    echo "Building $project"
    echo "--------------------------------------------"

    source ../build-module.sh

    # Return to the original directory
    cd "$mainDir"
}

# Initialize a variable with a list of folders for regular projects. The lambda functions are dependent on the core-framework
# so use the same python version. AWS maximum lambda runtime is "python3.12"
projects=(
    "sck-core-framework"
    "sck-core-db"
    "sck-core-execute"
    "sck-core-report"
    "sck-core-runner"
    "sck-core-component"
    "sck-core-deployspec"
    "sck-core-invoker"
    "sck-core-organization"
    "sck-core-api"
    "sck-core-codecommit"
    "sck-core-cli"
    "sck-core-docs"
)

for project in "${projects[@]}"; do
    Build_AppComponent "$project"
done
