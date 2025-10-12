#!/usr/bin/env python3
"""
Minimal version requirement checker without external dependencies.

Usage:
  python test-python.py "3.12"                 # exact major.minor
  python test-python.py ">=3.11,<3.13"         # comma-separated constraints

Exit codes:
  0 if current Python satisfies the spec
  1 if it does not
  2 on invalid arguments
"""

from __future__ import annotations

import operator
import sys
from typing import Callable, List, Tuple


def parse_version(version: str) -> Tuple[int, int]:
    """Parse '3.12' or '3.12.1' into (3, 12)."""
    parts = version.strip().split(".")
    if len(parts) < 2:
        raise ValueError("version must include major.minor")
    try:
        major = int(parts[0])
        minor = int(parts[1])
    except ValueError as exc:
        raise ValueError("version components must be integers") from exc
    return major, minor


OPS: dict[str, Callable[[Tuple[int, int], Tuple[int, int]], bool]] = {
    "==": operator.eq,
    "!=": operator.ne,
    ">=": operator.ge,
    "<=": operator.le,
    ">": operator.gt,
    "<": operator.lt,
}


def satisfies(current: Tuple[int, int], spec: str) -> bool:
    """Evaluate current major.minor against a simple spec string.

    Supports one or more comma-separated constraints with operators from OPS.
    If a token has no operator (e.g., '3.12'), it's treated as '==3.12'.
    """
    if not spec or not spec.strip():
        return False
    constraints: List[str] = [s.strip() for s in spec.split(",") if s.strip()]
    if not constraints:
        return False

    for token in constraints:
        op = None
        rhs = token
        for k in ("==", "!=", ">=", "<=", ">", "<"):
            if token.startswith(k):
                op = k
                rhs = token[len(k) :].strip()
                break
        if op is None:
            op = "=="
        try:
            target = parse_version(rhs)
        except Exception:
            return False
        if not OPS[op](current, target):
            return False
    return True


def main(argv: list[str]) -> int:
    spec = argv[1] if len(argv) > 1 else ">=3.11,<3.13"
    current = (sys.version_info.major, sys.version_info.minor)
    return 0 if satisfies(current, spec) else 1


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except Exception:
        sys.exit(2)
