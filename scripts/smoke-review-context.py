#!/usr/bin/env python3
"""Smoke-test review-context.py with UTF-8 Git output on every host locale."""

import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WRAPPER = ROOT / "scripts/review-context.py"


def run(command: list[str], cwd: Path, *, check: bool = True) -> subprocess.CompletedProcess[bytes]:
    result = subprocess.run(
        command,
        cwd=cwd,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if check and result.returncode != 0:
        stderr = result.stderr.decode("utf-8", errors="replace").strip()
        raise RuntimeError(f"{' '.join(command)} failed: {stderr}")
    return result


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="review-context-utf8-") as temp_dir:
        repo = Path(temp_dir)
        run(["git", "init", "--quiet"], repo)
        run(["git", "config", "user.email", "review-context@example.invalid"], repo)
        run(["git", "config", "user.name", "Review Context Smoke"], repo)
        run(["git", "config", "core.autocrlf", "false"], repo)

        tracked = repo / "review.txt"
        tracked.write_text("baseline\n", encoding="utf-8")
        run(["git", "add", "review.txt"], repo)
        run(["git", "commit", "--quiet", "-m", "baseline"], repo)
        tracked.write_text("baseline\n中文 → review 🟢\n", encoding="utf-8")

        result = subprocess.run(
            [sys.executable, str(WRAPPER)],
            cwd=repo,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        stdout = result.stdout.decode("utf-8", errors="replace")
        stderr = result.stderr.decode("utf-8", errors="replace")
        if result.returncode != 0:
            print(f"review-context smoke test failed ({result.returncode}): {stderr.strip()}", file=sys.stderr)
            return 1
        if "中文 → review 🟢" not in stdout:
            print("review-context smoke test did not preserve UTF-8 diff content", file=sys.stderr)
            return 1

    print("review-context UTF-8 smoke test passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
