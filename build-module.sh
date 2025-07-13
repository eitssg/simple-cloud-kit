#!/bin/bash

# if the paremter $1 is empty then default to "module"
version=${4:-3.13.1}
clean=${5}

# if the file pyproject.toml does not exist, return with error "Must be in project folder":
if [ ! -f "pyproject.toml" ]; then
    echo "Must be in project folder"
    exit 1
fi

# Source and execute the build script
source ../build.sh

# Source and execute the flakeit script
source ../flakeit.sh

# Source and execute the pytest script
source ../pytest.sh

# Source and execute the publish script
source ../publish.sh

# if the file .lambda exists, then it is a lambda module
if [ -f ".lambda" ]; then
    source ../package.sh
fi
