#!/usr/bin/env bash
#
# scripts/validate.sh — standing consistency guard for the spec_driven_develop repo.
#
# Runs ten checks and prints one PASS/FAIL line per check. Exits non-zero if any
# check fails. Safe to run from any directory: the script cds to the repo root
# (the parent of this scripts/ directory) before doing any work.
#
# Dependencies (no new ones introduced):
#   - bash
#   - python3 or python (standard library only)
#   - node   (required for check (e); absence is a loud FAILURE, not a skip)
#   - git    (used to enumerate tracked files for check (a))
#
# Design choice (per task T1.4): path-reference extraction in check (a) is
# implemented in Python stdlib rather than ripgrep (rg). This keeps the guard
# free of any rg dependency so it runs identically on machines without ripgrep.
#
# Checks:
#   (a) Reference existence  — backtick-quoted relative paths found in tracked
#        .md/.json/.js files must resolve to an existing file/dir. Candidates
#        containing template placeholders (<, >, {, }, *) or whitespace are
#        skipped. Resolution rules:
#          * paths starting with plugins/ or scripts/ resolve from the repo root;
#          * paths containing a references/, agents/, or templates/ segment that
#            name a file (basename has an extension) are tried against the repo
#            root, the referencing file's directory and each of its ancestors,
#            and every skill root (plugins/*\/skills/*/). The first base that
#            resolves wins. This matches how the skills and agent prompts write
#            skill-internal references (relative to the skill root).
#        docs/archives/ is excluded from scanning: those are frozen historical
#        snapshots whose internal references are intentionally not maintained.
#   (b) Manifest <-> filesystem parity — for plugins/spec-driven-develop/
#        .claude-plugin/plugin.json: every path in its agents (and commands, while
#        present) arrays exists on disk; no unlisted files live in agents/ (or
#        commands/); and every readPrompt("...") literal in opencode-plugin.js
#        resolves. An absent commands array is TOLERATED (it is slated for
#        deletion in a later phase, which must not require editing this script).
#   (c) Version parity — the version string must be identical across four sites:
#        SKILL.md frontmatter, .claude-plugin/plugin.json, .codex-plugin/
#        plugin.json, and the root .claude-plugin/marketplace.json (.plugins[0]).
#   (d) JSON validity — the four manifests above plus .agents/plugins/
#        marketplace.json must each parse as JSON.
#   (e) ESM syntax — `node --check --input-type=module` on opencode-plugin.js
#        (plain `node --check` parses as CommonJS and fails on `import`).
#   (f) py_compile — the three Python files must byte-compile.
#   (g) Exporter smoke test — run scripts/export-progress.py against the
#        known-good fixture in scripts/test-fixtures/progress/ and assert the
#        JSON structure (task name, one phase with two tasks, two parsed tasks
#        with non-empty priority/acceptance).
#   (h) Review context UTF-8 smoke test — create a temporary Git repository with
#        Chinese, arrow, and emoji characters, then run the packaged collector
#        without relying on the host locale or stdout code page.
#   (i) Bundled installer bootstrap/repair plus frontmatter-version smoke test.
#   (j) Workflow contract invariants for archive, payload/state, templates,
#       single-sourcing, and GitHub recovery semantics.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

FAILURES=0

if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN=python
else
  PYTHON_BIN=''
fi

python_cmd() {
  if [[ -z "$PYTHON_BIN" ]]; then
    echo "Python interpreter not found (tried python3 and python)" >&2
    return 1
  fi
  "$PYTHON_BIN" "$@"
}

run_check() {
  local id="$1"; shift
  local desc="$1"; shift
  if "$@"; then
    echo "[PASS] ($id) $desc"
  else
    echo "[FAIL] ($id) $desc"
    FAILURES=$((FAILURES + 1))
  fi
}

# ---------------------------------------------------------------------------
# (a) Reference existence
# ---------------------------------------------------------------------------
check_a() {
  python_cmd - <<'PY'
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(".").resolve()
EXCLUDE_PREFIX = "docs/archives/"
SEGMENTS = ("references/", "agents/", "templates/")
SKIP_CHARS = set("<>{}*")
BACKTICK = re.compile(r"`([^`\n]+)`")

try:
    tracked = subprocess.check_output(["git", "ls-files"], text=True).splitlines()
except Exception as exc:  # pragma: no cover - git should always be present here
    print(f"check (a): cannot enumerate tracked files: {exc}", file=sys.stderr)
    sys.exit(1)

files = [
    f for f in tracked
    if f.endswith((".md", ".json", ".js")) and not f.startswith(EXCLUDE_PREFIX)
]

SKILL_ROOTS = sorted(ROOT.glob("plugins/*/skills/*/"))


def classify(candidate):
    c = candidate.strip()
    if not c or any(ch in c for ch in SKIP_CHARS):
        return None
    if any(ch.isspace() for ch in c):
        return None
    if c.startswith(("plugins/", "scripts/")):
        return ("root", c)
    for seg in SEGMENTS:
        if c.startswith(seg) or ("/" + seg) in c:
            base = c.rstrip("/").rsplit("/", 1)[-1]
            if "." in base:  # names a file rather than a bare directory segment
                return ("rel", c)
            return None
    return None


def rel_bases(referencing_file):
    yield ROOT
    parent = (ROOT / referencing_file).parent
    while True:
        yield parent
        if parent == ROOT:
            break
        parent = parent.parent
    for sr in SKILL_ROOTS:
        yield sr


def resolves(kind, candidate, referencing_file):
    if kind == "root":
        return (ROOT / candidate).exists()
    return any((b / candidate).exists() for b in rel_bases(referencing_file))


missing = []
for f in files:
    try:
        text = (ROOT / f).read_text(encoding="utf-8")
    except OSError:
        continue  # tracked but unreadable/removed on disk; nothing to scan
    for m in BACKTICK.finditer(text):
        cl = classify(m.group(1))
        if not cl:
            continue
        kind, candidate = cl
        if not resolves(kind, candidate, f):
            missing.append((candidate, f))

if missing:
    for candidate, f in missing:
        print(f"check (a): broken reference `{candidate}` in {f}", file=sys.stderr)
    sys.exit(1)
sys.exit(0)
PY
}

# ---------------------------------------------------------------------------
# (b) Manifest <-> filesystem parity
# ---------------------------------------------------------------------------
check_b() {
  python_cmd - <<'PY'
import json
import re
import sys
from pathlib import Path

PLUGIN = Path("plugins/spec-driven-develop")
MANIFEST = PLUGIN / ".claude-plugin" / "plugin.json"

errors = []
try:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
except Exception as exc:
    print(f"check (b): cannot parse {MANIFEST}: {exc}", file=sys.stderr)
    sys.exit(1)

# 1) Every path listed in agents/ (and commands/, while present) exists; and
# 2) no unlisted files live in the corresponding directory. An absent key is
#    tolerated so a future phase that drops `commands` needs no edit here.
for key in ("agents", "commands"):
    entries = manifest.get(key)
    if entries is None:
        continue
    listed_names = set()
    for entry in entries:
        listed_names.add(Path(entry).name)
        if not (PLUGIN / entry).exists():
            errors.append(f"listed {key} entry missing on disk: {entry}")
    directory = PLUGIN / key
    if directory.is_dir():
        for f in sorted(directory.iterdir()):
            if f.is_file() and f.name not in listed_names:
                errors.append(f"unlisted file in {key}/: {f.name}")

# 3) Every readPrompt("...") literal in opencode-plugin.js resolves.
js_path = PLUGIN / "opencode-plugin.js"
try:
    js = js_path.read_text(encoding="utf-8")
except OSError as exc:
    errors.append(f"cannot read {js_path}: {exc}")
else:
    for m in re.finditer(r"readPrompt\([\"']([^\"']+)[\"']\)", js):
        rel = m.group(1)
        if not (PLUGIN / rel).exists():
            errors.append(f"readPrompt target missing: {rel}")

if errors:
    for e in errors:
        print(f"check (b): {e}", file=sys.stderr)
    sys.exit(1)
sys.exit(0)
PY
}

# ---------------------------------------------------------------------------
# (c) Version parity
# ---------------------------------------------------------------------------
check_c() {
  python_cmd - <<'PY'
import json
import re
import sys
from pathlib import Path

PLUGIN = Path("plugins/spec-driven-develop")


def skill_version():
    text = (PLUGIN / "skills" / "spec-driven-develop" / "SKILL.md").read_text(
        encoding="utf-8"
    )
    fm = re.match(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
    block = fm.group(1) if fm else text
    m = re.search(r"^\s*version:\s*(.+?)\s*$", block, re.MULTILINE)
    return m.group(1) if m else None


def json_version(path, key_path):
    try:
        data = json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"check (c): cannot parse {path}: {exc}", file=sys.stderr)
        return None
    node = data
    for key in key_path:
        if not isinstance(node, (dict, list)):
            return None
        try:
            node = node[key]
        except (KeyError, IndexError, TypeError):
            return None
    return node


versions = {
    "SKILL.md frontmatter": skill_version(),
    "plugins/spec-driven-develop/.claude-plugin/plugin.json": json_version(
        PLUGIN / ".claude-plugin" / "plugin.json", ["version"]
    ),
    "plugins/spec-driven-develop/.codex-plugin/plugin.json": json_version(
        PLUGIN / ".codex-plugin" / "plugin.json", ["version"]
    ),
    ".claude-plugin/marketplace.json": json_version(
        ".claude-plugin/marketplace.json", ["plugins", 0, "version"]
    ),
}

distinct = set(versions.values())
if None in distinct or len(distinct) != 1:
    for site, value in versions.items():
        print(f"check (c):   {site}: {value}", file=sys.stderr)
    print("check (c): version mismatch across sites", file=sys.stderr)
    sys.exit(1)
sys.exit(0)
PY
}

# ---------------------------------------------------------------------------
# (d) JSON validity
# ---------------------------------------------------------------------------
check_d() {
  python_cmd - <<'PY'
import json
import sys
from pathlib import Path

MANIFESTS = [
    "plugins/spec-driven-develop/.claude-plugin/plugin.json",
    "plugins/spec-driven-develop/.codex-plugin/plugin.json",
    ".claude-plugin/marketplace.json",
    ".agents/plugins/marketplace.json",
]

bad = []
for f in MANIFESTS:
    try:
        json.loads(Path(f).read_text(encoding="utf-8"))
    except Exception as exc:
        bad.append(f"{f}: {exc}")

if bad:
    for b in bad:
        print(f"check (d): invalid JSON {b}", file=sys.stderr)
    sys.exit(1)
sys.exit(0)
PY
}

# ---------------------------------------------------------------------------
# (e) ESM syntax of the OpenCode plugin entrypoint
# ---------------------------------------------------------------------------
check_e() {
  if ! command -v node >/dev/null 2>&1; then
    echo "check (e): node not found; cannot run ESM syntax check" >&2
    return 1
  fi
  node --check --input-type=module < plugins/spec-driven-develop/opencode-plugin.js
}

# ---------------------------------------------------------------------------
# (f) py_compile the Python sources
# ---------------------------------------------------------------------------
check_f() {
  python_cmd -m py_compile \
    scripts/export-progress.py \
    scripts/review-context.py \
    plugins/spec-driven-develop/skills/review-spd/scripts/review-context.py
}

# ---------------------------------------------------------------------------
# (g) Exporter smoke test against the known-good fixture
# ---------------------------------------------------------------------------
check_g() {
  python_cmd - <<'PY'
import json
import subprocess
import sys

result = subprocess.run(
    [sys.executable, "scripts/export-progress.py", "scripts/test-fixtures/progress/"],
    capture_output=True,
    text=True,
)
if result.returncode != 0:
    print(f"check (g): exporter exited {result.returncode}: {result.stderr.strip()}",
          file=sys.stderr)
    sys.exit(1)

try:
    data = json.loads(result.stdout)
except json.JSONDecodeError as exc:
    print(f"check (g): exporter output is not valid JSON: {exc}", file=sys.stderr)
    sys.exit(1)

errors = []
if data.get("task") != "Exporter Smoke Fixture":
    errors.append(f"unexpected task name: {data.get('task')!r}")
if data.get("mode") != "LOCAL_ONLY":
    errors.append(f"unexpected mode: {data.get('mode')!r}")
if data.get("workflow_run_id") != "spd-20260101-exporter-fixture-a1b2":
    errors.append(f"unexpected workflow_run_id: {data.get('workflow_run_id')!r}")
status = data.get("current_status", {})
if status.get("blockers") != "None":
    errors.append(f"unexpected blockers: {status.get('blockers')!r}")
if not status.get("adaptive_response"):
    errors.append("current_status has empty adaptive_response")

phases = data.get("phases", [])
if len(phases) != 1:
    errors.append(f"expected 1 phase, got {len(phases)}")
else:
    phase = phases[0]
    if phase.get("total_tasks") != 2:
        errors.append(f"expected total_tasks == 2, got {phase.get('total_tasks')}")
    tasks = phase.get("tasks", [])
    if len(tasks) != 2:
        errors.append(f"expected 2 parsed tasks, got {len(tasks)}")
    for t in tasks:
        if not t.get("priority"):
            errors.append(f"task {t.get('id')} has empty priority")
        if not t.get("acceptance"):
            errors.append(f"task {t.get('id')} has empty acceptance")
        for field in ("delivery_batch", "dependencies", "super_drivers", "delivery_shape", "affected_files", "test_expectation", "governance_impact", "rollback"):
            if not t.get(field):
                errors.append(f"task {t.get('id')} has empty {field}")
        if not t.get("execution_event"):
            errors.append(f"task {t.get('id')} has empty execution_event")

if errors:
    for e in errors:
        print(f"check (g): {e}", file=sys.stderr)
    sys.exit(1)
sys.exit(0)
PY
}

# ---------------------------------------------------------------------------
# (h) Review context UTF-8 smoke test in a temporary Git repository
# ---------------------------------------------------------------------------
check_h() {
  python_cmd scripts/smoke-review-context.py
}

# ---------------------------------------------------------------------------
# (i) Bundled installer manifest and process-substitution repair smoke test
# ---------------------------------------------------------------------------
check_i() {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  mkdir -p "$tmp_dir/source"
  cp -R "$PWD/plugins/spec-driven-develop/skills/." "$tmp_dir/source/" || { rm -rf "$tmp_dir"; return 1; }
  python_cmd - "$tmp_dir/source/spec-driven-develop/SKILL.md" <<'PY' || { rm -rf "$tmp_dir"; return 1; }
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
needle = "metadata:\n"
if needle not in text:
    raise SystemExit("metadata frontmatter block not found")
path.write_text(
    text.replace(needle, "  version: decoy-description-value\nmetadata:\n", 1),
    encoding="utf-8",
)
PY
  local expected_version
  expected_version="$(python_cmd - <<'PY'
import re
from pathlib import Path

text = Path("plugins/spec-driven-develop/skills/spec-driven-develop/SKILL.md").read_text(encoding="utf-8")
frontmatter = re.match(r"^---\s*\n(.*?)\n---", text, re.DOTALL).group(1)
print(re.search(r"^\s*version:\s*(.+?)\s*$", frontmatter, re.MULTILINE).group(1))
PY
)" || { rm -rf "$tmp_dir"; return 1; }
  local lib_url
  if command -v cygpath >/dev/null 2>&1; then
    lib_url="file:///$(cygpath -m "$PWD/scripts/lib/install-bundled-skills.sh")"
  else
    lib_url="file://$PWD/scripts/lib/install-bundled-skills.sh"
  fi
  SPEC_DRIVEN_INSTALLER_LIB_URL="$lib_url" \
  SPEC_DRIVEN_SOURCE_DIR="$tmp_dir/source" \
  CODEX_HOME="$tmp_dir/codex" \
    bash <(cat scripts/install-codex.sh) >"$tmp_dir/install.log" || { rm -rf "$tmp_dir"; return 1; }
  grep -F "v$expected_version" "$tmp_dir/install.log" >/dev/null || { rm -rf "$tmp_dir"; return 1; }
  rm "$tmp_dir/codex/skills/review-spd/references/output-format.md" || { rm -rf "$tmp_dir"; return 1; }
  SPEC_DRIVEN_INSTALLER_LIB_URL="$lib_url" \
  SPEC_DRIVEN_SOURCE_DIR="$tmp_dir/source" \
  SPEC_DRIVEN_INSTALL_YES=1 \
  CODEX_HOME="$tmp_dir/codex" \
    bash <(cat scripts/install-codex.sh) >/dev/null || { rm -rf "$tmp_dir"; return 1; }
  test -s "$tmp_dir/codex/skills/review-spd/references/output-format.md" || { rm -rf "$tmp_dir"; return 1; }
  rm -rf "$tmp_dir"
}

# ---------------------------------------------------------------------------
# (j) Workflow contract invariants
# ---------------------------------------------------------------------------
check_j() {
  python_cmd - <<'PY'
import sys
from pathlib import Path

skill_root = Path("plugins/spec-driven-develop/skills/spec-driven-develop")
files = {
    "skill": skill_root / "SKILL.md",
    "readme": Path("README.md"),
    "readme_zh": Path("README.zh-CN.md"),
    "archive": skill_root / "references/templates/archive.md",
    "progress": skill_root / "references/templates/progress.md",
    "plan": skill_root / "references/templates/plan.md",
    "task_definition": skill_root / "references/templates/task-definition.md",
    "github": skill_root / "references/github-integration.md",
    "parallel": skill_root / "references/parallel-protocol.md",
    "behavioral": skill_root / "references/behavioral-rules.md",
}
texts = {name: path.read_text(encoding="utf-8") for name, path in files.items()}
errors = []

canonical_archive = "docs/archives/<project-name>/<run-id>/"
for name in ("skill", "readme", "archive"):
    if canonical_archive not in texts[name]:
        errors.append(f"{files[name]} lacks canonical archive path")
if "<project-name>-<run-id>" in texts["archive"] or "<project-name>-<run-id>" in texts["readme"]:
    errors.append("current archive docs still use the flattened project-run path")
if "./<project-name>/<run-id>/progress/MASTER.md" not in texts["archive"]:
    errors.append("archive index link does not match canonical nested path")
if "locally validated — awaiting remote sync" not in texts["archive"]:
    errors.append("archive index cannot represent pending remote synchronization")
for fp in (
    "## Archived MASTER.md Tombstone",
    "**Workflow State**: archived",
    "**Archive MASTER**:",
    "**Pending Operations**:",
):
    if fp not in texts["progress"]:
        errors.append(f"progress tombstone contract missing: {fp}")
if "spec-tav/v1" not in texts["skill"]:
    errors.append("SKILL.md lacks handoff contract ID spec-tav/v1")
if "do not reconstruct active task execution from the tombstone" not in texts["skill"]:
    errors.append("SKILL.md lacks completed-tombstone recovery semantics")

payload = "Outcome, Rework, Plan returns, Unplanned dependencies, and Focused S.U.P.E.R result"
if payload not in texts["skill"]:
    errors.append("SKILL.md lacks the canonical execution-event payload")
for fp in (
    "project-level lightweight status authority",
    "authoritative task-event records",
    "scoped to one task",
):
    if fp not in texts["skill"]:
        errors.append(f"SKILL.md state ownership missing: {fp}")

for heading in ("## Domain Decisions and Write-Back", "## S.U.P.E.R Priorities"):
    if heading not in texts["task_definition"]:
        errors.append(f"task-definition template missing {heading}")
if "references/super-philosophy.md" not in texts["plan"]:
    errors.append("plan template does not cite the canonical S.U.P.E.R reference")
if "**S (Single Purpose)**" in texts["plan"] or "**R (Replaceable Parts)**" in texts["plan"]:
    errors.append("plan template still redefines S.U.P.E.R principles")

for fp in (
    "exact lookup → contract check → reuse/create → immediate ledger write",
    "ITEM_MATCH_COUNT",
    "record ITEM_JSON id",
    "Field or item identity lookup/create failures are blocking",
):
    if fp not in texts["github"]:
        errors.append(f"GitHub recovery protocol missing: {fp}")
if "references/adaptive-control.md" not in texts["parallel"]:
    errors.append("parallel protocol does not delegate adaptive storage/activation")
if 'references/parallel-protocol.md` "Writer model"' not in texts["behavioral"]:
    errors.append("behavioral reviewer rule does not cite the canonical writer model")

for fp, name in (
    ("Separate tier vocabularies", "readme"),
    ("两套分级术语相互独立", "readme_zh"),
):
    if fp not in texts[name]:
        errors.append(f"README terminology distinction missing: {fp}")

if errors:
    for error in errors:
        print(f"check (j): {error}", file=sys.stderr)
    sys.exit(1)
PY
}

# ---------------------------------------------------------------------------
# Run all checks
# ---------------------------------------------------------------------------
run_check a "reference existence" check_a
run_check b "manifest <-> filesystem parity" check_b
run_check c "version parity" check_c
run_check d "JSON validity of manifests" check_d
run_check e "ESM syntax of opencode-plugin.js" check_e
run_check f "py_compile Python sources" check_f
run_check g "exporter smoke test (fixture)" check_g
run_check h "review-context UTF-8 smoke test" check_h
run_check i "bundled installer bootstrap and repair smoke test" check_i
run_check j "workflow contract invariants" check_j

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "validate.sh: $FAILURES check(s) FAILED" >&2
  exit 1
fi
echo "validate.sh: all 10 checks passed"
exit 0
