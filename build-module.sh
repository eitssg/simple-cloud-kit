#!/bin/bash

# if the paremter $1 is empty then default to "module"
type=${2:-module}
version=${4:-3.13.2}
clean=${5}

echo "Building module type: $type"

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if [ ! -f "pyproject.toml" ]; then
    echo "Must be in project folder"
    exit 1
fi

# Deactivarte the virtual environment if it is active
if [ ! "$VIRTUAL_ENV" = "" ]; then
   echo "Deactivating virtualenv"
   deactivate
fi

if [ "$clean" = "--clean" ]; then
   echo "Removing current virtualenv"
   if [ -d .venv ]; then
      rm -rf .venv
   fi
fi

if [ ! -d .venv ]; then
   echo "Creating new virtualenv"
   python -mvenv .venv
fi

echo "Activating virtualenv"
source .venv/bin/activate

# If the variable $client is equal to "-clean" then clear poetry caches
if [ "$clean" = "-clean" ]; then
   echo "Clearing poetry caches"
   poetry cache clear _default_cache --all --quiet
   poetry cache clear nexus --all --quiet
fi

# Source and execute the build script
source ../build.sh

# Source and execute the flakeit script
source ../flakeit.sh

# Source and execute the pytest script
source ../pytest.sh

# Source and execute the publish script
source ../publish.sh

if [ "$type" = "lambda" ]; then

    # Source and execute the package script
    source ../package.sh
fi
