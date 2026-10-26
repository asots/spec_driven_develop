#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
TARGET_SKILLS_DIR="$CODEX_HOME/skills"
PLATFORM_NAME="Codex"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALLER_LIB="$SCRIPT_DIR/lib/install-bundled-skills.sh"
if [ ! -f "$INSTALLER_LIB" ]; then
    INSTALLER_REF="${SPEC_DRIVEN_INSTALL_REF:-main}"
    INSTALLER_BOOTSTRAP_FILE="$(mktemp)"
    trap 'rm -f "$INSTALLER_BOOTSTRAP_FILE"' EXIT
    INSTALLER_LIB_URL="${SPEC_DRIVEN_INSTALLER_LIB_URL:-https://raw.githubusercontent.com/asots/spec_driven_develop/$INSTALLER_REF/scripts/lib/install-bundled-skills.sh}"
    curl -fsSL "$INSTALLER_LIB_URL" -o "$INSTALLER_BOOTSTRAP_FILE"
    INSTALLER_LIB="$INSTALLER_BOOTSTRAP_FILE"
fi

# shellcheck source=lib/install-bundled-skills.sh
source "$INSTALLER_LIB"
echo "Restart Codex to activate the skills."
