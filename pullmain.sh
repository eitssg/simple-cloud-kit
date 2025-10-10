#!/usr/bin/env bash
set -euo pipefail

# List of submodules/projects to update
A=(
  sck-core-api
  sck-core-cli
  sck-core-codecommit
  sck-core-component
  sck-core-db
  sck-core-deployspec
  sck-core-docker
  sck-core-docker-base
  sck-core-docker-server
  sck-core-docs
  sck-core-execute
  sck-core-framework
  sck-core-invoker
  sck-core-organization
  sck-core-report
  sck-core-runner
  sck-core-ui
  sck-core-ai
)

# Allow branch override via first argument (default: develop)
BRANCH=${1:-develop}

for B in "${A[@]}"; do
  echo "=== Updating ${B} on branch ${BRANCH} ==="
  if [[ ! -d "${B}" ]]; then
    echo "[skip] Directory '${B}' not found"
    continue
  fi

  pushd "${B}" >/dev/null

  # Ensure we have the latest refs
  git fetch --all --prune

  # Check out the branch locally (create and track origin if missing)
  if git rev-parse --verify "${BRANCH}" >/dev/null 2>&1; then
    git checkout "${BRANCH}"
  else
    git checkout -b "${BRANCH}" --track "origin/${BRANCH}" || git checkout "${BRANCH}"
  fi

  # Fast-forward only pull to avoid unintended merges
  if git rev-parse --verify "origin/${BRANCH}" >/dev/null 2>&1; then
    git pull --ff-only origin "${BRANCH}" || {
      echo "[warn] Fast-forward failed in ${B}. Resolve manually."
    }
  else
    echo "[info] Remote branch origin/${BRANCH} not found for ${B}"
  fi

  popd >/dev/null
done
