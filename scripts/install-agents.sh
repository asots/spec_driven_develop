#!/usr/bin/env bash
set -euo pipefail

TARGET_SKILLS_DIR="${AGENTS_HOME:-$HOME/.agents}/skills"
PLATFORM_NAME="shared agents"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALLER_LIB="$SCRIPT_DIR/lib/install-bundled-skills.sh"
if [ ! -f "$INSTALLER_LIB" ]; then
    INSTALLER_REF="${SPEC_DRIVEN_INSTALL_REF:-main}"
    INSTALLER_BOOTSTRAP_FILE="$(mktemp)"
    trap 'rm -f "$INSTALLER_BOOTSTRAP_FILE"' EXIT
    INSTALLER_LIB_URL="${SPEC_DRIVEN_INSTALLER_LIB_URL:-https://raw.githubusercontent.com/zhu1090093659/spec_driven_develop/$INSTALLER_REF/scripts/lib/install-bundled-skills.sh}"
    curl -fsSL "$INSTALLER_LIB_URL" -o "$INSTALLER_BOOTSTRAP_FILE"
    INSTALLER_LIB="$INSTALLER_BOOTSTRAP_FILE"
fi

# shellcheck source=lib/install-bundled-skills.sh
source "$INSTALLER_LIB"
echo "Restart the target agent to activate the skills."
