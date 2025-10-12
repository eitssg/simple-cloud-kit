#!/bin/bash

set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") [-dev] [-skip-tests] [-new] [--publish] [--package] [-h]

Options:
  -dev          Install with development extras (uv sync --all-extras)
  -skip-tests   Accepted for parity; this script does not run tests directly
    -new          Recreate venv (.venv) before install (same as env NEW=1)
    --publish     Run publish step after build/tests (if requested)
    --package     If .lambda exists, run package.sh to build Lambda bundle
  -h, --help    Show this help and exit.
EOF
}

DEV_FLAG=0
SKIP_TESTS_FLAG=0
NEW_FLAG=0
PACKAGE_FLAG=0
PUBLISH_FLAG=0

# Determine desired Python version for this module
get_desired_python_version() {
    if [[ -n "${PYTHON_VERSION:-}" ]]; then
        echo "$PYTHON_VERSION"; return
    fi
    if [[ -f ".python-version" ]]; then
        head -n1 .python-version | tr -d '[:space:]'; return
    fi
    if [[ -f "pyproject.toml" ]]; then
        local req
        req=$(grep -E "^\s*requires-python\s*=" pyproject.toml | head -n1 | sed -E 's/.*"([^"]+)".*/\1/' || true)
        if [[ -n "$req" ]]; then
            if [[ "$req" =~ 3\.12 ]]; then echo "3.12"; return; fi
            if [[ "$req" =~ ">?=\s*3\.11" && "$req" =~ "<\s*3\.13" ]]; then echo "3.12"; return; fi
            local exact
            exact=$(printf "%s" "$req" | grep -Eo '==\s*[0-9]+\.[0-9]+' | sed 's/==\s*//' | head -n1 || true)
            if [[ -n "$exact" ]]; then echo "$exact"; return; fi
            local simple
            simple=$(printf "%s" "$req" | grep -Eo '[0-9]+\.[0-9]+' | head -n1 || true)
            if [[ "$simple" == "3.11" ]]; then echo "3.12"; return; fi
            if [[ -n "$simple" ]]; then echo "$simple"; return; fi
        fi
    fi
    echo "3.12"
}

ensure_python_version_installed() {
    local desired="$1"

    echo "Desired Python version: $desired"

    uv run ../test-python.py $desired
    if [[ $? -ne 0 ]]; then
        echo "Python $desired is not installed. aborting..."
        exit 1
    fi

    echo "Python $desired is installed."
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -dev)
            DEV_FLAG=1
            shift
            ;;
        -skip-tests)
            SKIP_TESTS_FLAG=1
            shift
            ;;
        -new)
            NEW_FLAG=1
            shift
            ;;
        --package)
            PACKAGE_FLAG=1
            shift
            ;;
        --publish)
            PUBLISH_FLAG=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 2
            ;;
    esac
done

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

if [[ "${NEW:-0}" == "1" || "$NEW_FLAG" == "1" ]]; then
    rm .python-version
    echo "Removing virtual env"
    rm -rf .venv
fi

# Ensure desired Python is installed and create venv with it
desired_py=$(get_desired_python_version)
ensure_python_version_installed "$desired_py"

# if the .venv folder does not exist, create it (prefer uv-located interpreter when available)
if [ ! -d ".venv" ]; then
    if command -v uv >/dev/null 2>&1; then
        # Get the absolute path to the interpreter uv would use
        py_bin=$(uv python find "$desired_py" 2>/dev/null | head -n1)
        if [[ -n "$py_bin" && -x "$py_bin" ]]; then
            "$py_bin" -m venv .venv
        else
            python -m venv .venv
        fi
    else
        python -m venv .venv
    fi
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

echo -e "\n---- Installing the project and dependencies using UV"


# Install project dependencies
if [[ "$DEV_FLAG" == "1" || "${DEV:-0}" == "1" ]]; then
    echo "Installing with DEVELOPMENT tools"
    uv sync --all-extras
else
    uv sync
fi

echo -e "\n---- Building the distribution files for project: $packageName v${version}"

uv build

distPath="../sck-core-docker/dist"
mkdir -p "$distPath"

filePrefix=$(echo "$packageName" | sed 's/-/_/g')

# if the dist folder contains files with the project prefix remove them
rm -f "$distPath/$filePrefix*"

# Copy the files from the dist folder to the destination folder
cp -r dist/* "$distPath/"

echo -e "\n---- Distribution files copied to $distPath"
echo -e "\n---- Build complete for project: $packageName v${version}"

# Static checks when dev is enabled
if [[ "$DEV_FLAG" == "1" ]]; then
    # Lint/format gate
    if [ -f "../flakeit.sh" ]; then
        # shellcheck source=/dev/null
        source ../flakeit.sh
    fi
fi

# Tests when dev is enabled and not skipped
if [[ "$DEV_FLAG" == "1" && "$SKIP_TESTS_FLAG" != "1" ]]; then
    if [ -f "../pytest.sh" ]; then
        # shellcheck source=/dev/null
        source ../pytest.sh
    fi
fi

# if the file .lambda exists then execute package.sh script
if [ -f ".lambda" ] && [ "$PACKAGE_FLAG" -eq 1 ]; then
    . ../package.sh
fi

# Publish only when requested
if [[ "$PUBLISH_FLAG" == "1" ]]; then
    if [ -f "../publish.sh" ]; then
        # shellcheck source=/dev/null
        source ../publish.sh
    fi
fi
