#!/bin/bash

set -euo pipefail

usage() {
	cat <<EOF
Usage: $(basename "$0") [-dev] [-skip-tests] [-new] [-h]

Options:
  -dev          Enable development mode; forwarded to build.sh
  -skip-tests   Skip running tests (skips pytest step here and forwarded to build.sh)
	-new          Recreate venv before build (forwarded to build.sh)
	--publish     Run publish step at the end
	-h, --help    Show this help and exit.
EOF
}

DEV_FLAG=0
SKIP_TESTS_FLAG=0
NEW_FLAG=0
PUBLISH_FLAG=0


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

# Build argument list for build.sh
build_args=()
if [[ "$DEV_FLAG" == "1" ]]; then
	build_args+=("-dev")
fi
if [[ "$SKIP_TESTS_FLAG" == "1" ]]; then
	build_args+=("-skip-tests")
fi
if [[ "$NEW_FLAG" == "1" ]]; then
	build_args+=("-new")
fi

# Build (honors -dev and -skip-tests)
if ((${#build_args[@]})); then
	bash ../build.sh "${build_args[@]}"
else
	bash ../build.sh
fi

# Run static checks only when dev is enabled
if [[ "$DEV_FLAG" == "1" ]]; then
	source ../flakeit.sh
fi

# Run tests only when dev is enabled and not skipped
if [[ "$DEV_FLAG" == "1" && "$SKIP_TESTS_FLAG" != "1" ]]; then
	source ../pytest.sh
fi

# Publish only when requested
if [[ "$PUBLISH_FLAG" == "1" ]]; then
	source ../publish.sh
fi
