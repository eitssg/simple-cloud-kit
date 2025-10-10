#!/bin/bash

set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") [-dev] [-skip-tests] [-new] [--publish] [-h]

Options:
    --dev          Enable development mode (pass to sub-builds). Typically triggers 'uv sync --all-extras'.
    --skip-tests   Skip running tests (passed through; sub-builds will not execute pytest).
    --new          Recreate venvs in sub-builds (fresh .venv)
    --publish     Run publish step in sub-builds at the end
    --package     If .lambda exists, run package.sh to build Lambda bundle
    -h, --help    Show this help and exit.

Examples:
  $(basename "$0")
  $(basename "$0") --dev
  $(basename "$0") --publish
  $(basename "$0") --package
  $(basename "$0") --skip-tests
  $(basename "$0") --dev --skip-tests
  $(basename "$0") --new
EOF
}

DEV_FLAG=0
SKIP_TESTS_FLAG=0
NEW_FLAG=0
PUBLISH_FLAG=0

# Determine desired Python version from the current directory (module)
get_desired_python_version() {
    # Priority: env PYTHON_VERSION -> .python-version -> [project].requires-python -> default 3.12
    if [[ -n "${PYTHON_VERSION:-}" ]]; then
        echo "$PYTHON_VERSION"
        return
    fi
    if [[ -f ".python-version" ]]; then
        head -n1 .python-version | tr -d '[:space:]'
        return
    fi
    if [[ -f "pyproject.toml" ]]; then
        # Try PEP 621 requires-python
        local req
        req=$(grep -E "^\s*requires-python\s*=" pyproject.toml | head -n1 | sed -E 's/.*"([^"]+)".*/\1/' || true)
        if [[ -n "$req" ]]; then
            # Prefer 3.12 when allowed by the range (e.g., ">=3.11,<3.13")
            if [[ "$req" =~ 3\.12 ]]; then
                echo "3.12"; return
            fi
            if [[ "$req" =~ ">?=\s*3\.11" && "$req" =~ "<\s*3\.13" ]]; then
                echo "3.12"; return
            fi
            # Exact pin (==3.x)
            local exact
            exact=$(printf "%s" "$req" | grep -Eo '==\s*[0-9]+\.[0-9]+' | sed 's/==\s*//' | head -n1 || true)
            if [[ -n "$exact" ]]; then
                echo "$exact"; return
            fi
            # Fallback: first major.minor, but avoid choosing 3.11 by default
            local simple
            simple=$(printf "%s" "$req" | grep -Eo '[0-9]+\.[0-9]+' | head -n1 || true)
            if [[ "$simple" == "3.11" ]]; then
                echo "3.12"; return
            fi
            if [[ -n "$simple" ]]; then
                echo "$simple"; return
            fi
        fi
        # No Poetry support; repository uses uv only
    fi
    echo "3.12"
}

ensure_python_version_installed() {
    local desired="$1"
    # Prefer accepting current python first
    if command -v python >/dev/null 2>&1; then
        if python "$(dirname "$0")/test-python.py" "$desired" >/dev/null 2>&1; then
            local cur
            cur=$(python - <<'PY'
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}")
PY
)
            echo "Using current Python ${cur} (satisfies '$desired')"
            return 0
        fi
    fi

    # Otherwise require uv to have the interpreter installed
    if command -v uv >/dev/null 2>&1; then
        if ! uv python find "$desired" >/dev/null 2>&1; then
            echo "Required Python $desired is not installed (uv). Install it with: uv python install $desired" >&2
            exit 1
        fi
        echo "Resolved Python via uv (satisfies '$desired')"
        return 0
    fi

    # Fallback strict check without uv
    if command -v python >/dev/null 2>&1; then
        local cur
        cur=$(python - <<'PY'
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}")
PY
)
        if [[ "$cur" == "$desired" ]]; then
            echo "Using current Python ${cur} (exact match)"
            return 0
        fi
        echo "Python $desired required but current python is $cur. Install with uv or adjust PATH." >&2
        exit 1
    fi
    echo "uv not found and python not available to verify version. Please install uv or Python $desired." >&2
    exit 1
}

# Root-level Python version check (once)
root_desired_py=$(get_desired_python_version)
ensure_python_version_installed "$root_desired_py"

# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dev)
            DEV_FLAG=1
            shift
            ;;
        --skip-tests)
            SKIP_TESTS_FLAG=1
            shift
            ;;
        --new)
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
    pushd "$project" >/dev/null

    echo -e "\n\n--------------------------------------------"
    echo "Building $project"
    echo "--------------------------------------------"

    # Per-module Python enforcement happens in build.sh; no per-project check here

    # Build the argument list to forward directly to build.sh
    local -a forward_args=()
    if [[ "$DEV_FLAG" == "1" ]]; then
        forward_args+=("-dev")
    fi
    if [[ "$SKIP_TESTS_FLAG" == "1" ]]; then
        forward_args+=("-skip-tests")
    fi
    if [[ "$NEW_FLAG" == "1" ]]; then
        forward_args+=("-new")
    fi
    if [[ "$PUBLISH_FLAG" == "1" ]]; then
        forward_args+=("--publish")
    fi

    # Execute the build
    if ((${#forward_args[@]})); then
        bash ../build.sh "${forward_args[@]}"
    else
        bash ../build.sh
    fi

    # Return to the original directory
    popd >/dev/null
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
    "sck-core-ai"
    "sck-core-docs"
)

for project in "${projects[@]}"; do
    Build_AppComponent "$project"
done
