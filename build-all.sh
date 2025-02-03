#!/bin/bash

# if the file build-all.sh does not exist, return with error "Must be in main toolkit folder":
if [ ! -f "./build-all.sh" ]; then
    echo "Must be in main toolkit folder"
    exit 1
fi

# Function to build and package a project
Build_AppComponent() {
    local project=$1
    local type=$2
    local version=$3
    local clean=$4

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

    echo "We want python $version"
    echo "Active python version is: $(python --version)"

    # Remove poetry.lock if it exists (this is temporary)
    if [ -f "poetry.lock" ]; then
        rm -f "poetry.lock"
    fi

    source ../build-module.sh -type "$type" -version "$version" "$clean"

    # Return to the original directory
    cd "$mainDir"
}

# Function to build all components
Build_AllComponents() {
    local type=$1
    local version=$2
    shift 2
    local projects=("$@")

    for project in "${projects[@]}"; do
        Build_AppComponent "$project" "$type" "$version" "$clean"
    done
}

# Initialize a variable with a list of folders for regular projects. The lambda functions are dependent on the core-framework
# so use the same python version. AWS maximum lambda runtime is "python3.12"
core_projects=(
    "sck-core-framework"
    "sck-core-db"
)

Build_AllComponents "app" "3.13.1" "${core_projects[@]}"

# Initialize a variable with a list of folders for Lambda projects
# core-lambda-api is dependent on the core-framework so use the same python version. AWS maximum lambda runtime is "python3.12"
lambdaProjects=(
    "sck-core-report"
    "sck-core-execute"
    "sck-core-runner"
    "sck-core-component"
    "sck-core-deployspec"
    "sck-core-invoker"
    "sck-core-organization"
    "sck-core-api"
    "sck-core-codecommit"
)

Build_AllComponents "lambda" "3.13.1" "${lambdaProjects[@]}"

# Initialize a variable with a list of folders for regular projects
cli_projects=(
    "sck-core-cli"
    "sck-core-docs"
)

# Build all command-line apps and modules with python 3.12.4. There are only 2 "command line" executable
# sck-mod-core and docs. sck-mod-core command is "core", and docs command is "core-docs"
Build_AllComponents "app" "3.13.1" "${cli_projects[@]}"
