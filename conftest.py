"""Root test configuration for the monorepo.

This file exists ONLY to prevent a pytest invocation run from the
`simple-cloud-kit/` root from descending into the mounted submodule
workspaces (each `sck-core-*` directory).  Each submodule manages its
own test configuration, virtual environment expectations, and its own
`conftest.py`.  Allowing root-level discovery to walk into those
directories causes:

1. ImportPathMismatchError collisions (duplicate `tests.conftest` names)
2. Cross-environment leakage (different dependency graphs / pinned versions)
3. Slower end-to-end test cycles

We therefore instruct pytest's collector to ignore every `sck-core-*`
folder when (and only when) pytest is launched from the monorepo root.

If you WANT to run a submodule's tests, `cd` into that submodule first
(e.g., `cd sck-core-api; pytest`).  Do NOT remove this file unless you
replace it with an equivalent ignore mechanism.
"""

from __future__ import annotations

# Pytest hook variable: any globs listed here are ignored during collection.
# A single glob pattern is sufficient because each submodule sits directly
# under the repository root, e.g. `sck-core-api`, `sck-core-framework`, etc.
collect_ignore_glob = ["sck-core-*"]

# Safety note: This does NOT prevent those folders from running tests when
# pytest is invoked INSIDE the submodule (collector root changes). It only
# affects root-level runs.
