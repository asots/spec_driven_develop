#!/usr/bin/env python3
"""Repository convenience wrapper for the packaged Review skill context script."""

import runpy
import sys
from pathlib import Path


def main() -> int:
    script = Path(__file__).resolve().parents[1] / "plugins/spec-driven-develop/skills/review/scripts/review-context.py"
    if not script.is_file():
        print(f"Error: packaged review context script not found: {script}", file=sys.stderr)
        return 1
    runpy.run_path(str(script), run_name="__main__")
    return 0


if __name__ == "__main__":
    sys.exit(main())
