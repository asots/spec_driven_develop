#!/usr/bin/env bash
# Shared transactional installer for the bundled Markdown skills.
# Caller must set TARGET_SKILLS_DIR and PLATFORM_NAME before sourcing this file.

: "${TARGET_SKILLS_DIR:?TARGET_SKILLS_DIR must be set by the platform wrapper}"
: "${PLATFORM_NAME:?PLATFORM_NAME must be set by the platform wrapper}"

SKILL_NAME="spec-driven-develop"
INSTALLER_REF="${SPEC_DRIVEN_INSTALL_REF:-main}"
REPO_URL="https://github.com/zhu1090093659/spec_driven_develop"
RAW_URL="https://raw.githubusercontent.com/zhu1090093659/spec_driven_develop/$INSTALLER_REF"
SKILLS_SUBPATH="plugins/spec-driven-develop/skills"
SKILL_SUBPATH="$SKILLS_SUBPATH/$SKILL_NAME"
BUNDLED_SKILLS=("spec-driven-develop" "deep-discuss" "review-spd")
BUNDLED_REQUIRED_FILES=(
    "deep-discuss/SKILL.md"
    "review-spd/SKILL.md"
    "review-spd/references/output-format.md"
    "review-spd/references/reviewer-template.md"
    "review-spd/scripts/review-context.py"
    "spec-driven-develop/SKILL.md"
    "spec-driven-develop/references/adaptive-control.md"
    "spec-driven-develop/references/behavioral-rules.md"
    "spec-driven-develop/references/decomposition-strategy.md"
    "spec-driven-develop/references/domain-modeling.md"
    "spec-driven-develop/references/github-integration.md"
    "spec-driven-develop/references/parallel-protocol.md"
    "spec-driven-develop/references/super-philosophy.md"
    "spec-driven-develop/references/templates/analysis.md"
    "spec-driven-develop/references/templates/archive.md"
    "spec-driven-develop/references/templates/github-sync.md"
    "spec-driven-develop/references/templates/governance.md"
    "spec-driven-develop/references/templates/plan.md"
    "spec-driven-develop/references/templates/progress.md"
    "spec-driven-develop/references/templates/task-definition.md"
    "spec-driven-develop/references/wayfinding.md"
)
TARGET_DIR="$TARGET_SKILLS_DIR/$SKILL_NAME"
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$SCRIPT_ROOT/.." && pwd)"
LOCAL_SOURCE_DIR="${SPEC_DRIVEN_SOURCE_DIR:-$REPO_ROOT/$SKILLS_SUBPATH}"
TRANSACTION_ROOT=""

cleanup_installer() {
    if [ -n "$TRANSACTION_ROOT" ] && [ -d "$TRANSACTION_ROOT" ]; then
        rm -rf "$TRANSACTION_ROOT"
    fi
    if [ -n "${INSTALLER_BOOTSTRAP_FILE:-}" ] && [ -f "$INSTALLER_BOOTSTRAP_FILE" ]; then
        rm -f "$INSTALLER_BOOTSTRAP_FILE"
    fi
}
trap cleanup_installer EXIT

extract_version_stream() {
    awk '
        NR == 1 {
            sub(/\r$/, "", $0)
            if ($0 != "---") exit 1
            in_frontmatter = 1
            next
        }
        in_frontmatter {
            line = $0
            sub(/\r$/, "", line)
            if (line == "---") exit found ? 0 : 1
            if (line ~ /^metadata:[[:space:]]*$/) {
                in_metadata = 1
                next
            }
            if (in_metadata && line ~ /^[^[:space:]]/) in_metadata = 0
            if (in_metadata && line ~ /^  version:[[:space:]]*/) {
                sub(/^  version:[[:space:]]*/, "", line)
                print line
                found = 1
                exit 0
            }
        }
        END { if (!found) exit 1 }
    '
}

extract_version() {
    extract_version_stream < "$1" 2>/dev/null
}

get_local_version() {
    local skill_file="$TARGET_DIR/SKILL.md"
    if [ -f "$skill_file" ]; then
        extract_version "$skill_file"
    fi
}

get_source_version() {
    local local_skill="$LOCAL_SOURCE_DIR/$SKILL_NAME/SKILL.md"
    if [ -f "$local_skill" ]; then
        extract_version "$local_skill"
    else
        curl -fsSL "$RAW_URL/$SKILL_SUBPATH/SKILL.md" | extract_version_stream
    fi
}

bundle_is_complete() {
    local root="$1"
    local required_file
    for required_file in "${BUNDLED_REQUIRED_FILES[@]}"; do
        [ -s "$root/$required_file" ] || return 1
    done
}

bundle_has_existing_target() {
    local skill
    for skill in "${BUNDLED_SKILLS[@]}"; do
        [ -e "$TARGET_SKILLS_DIR/$skill" ] && return 0
    done
    return 1
}

confirm_install() {
    if [ "${SPEC_DRIVEN_INSTALL_YES:-0}" = "1" ]; then
        return 0
    fi
    read -p "Install/repair bundled skills? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

stage_bundle() {
    mkdir -p "$TARGET_SKILLS_DIR"
    TRANSACTION_ROOT="$(mktemp -d "$TARGET_SKILLS_DIR/.spec-driven-install.XXXXXX")"
    local staged_bundle="$TRANSACTION_ROOT/new"
    mkdir -p "$staged_bundle"

    if [ -d "$LOCAL_SOURCE_DIR" ]; then
        cp -R "$LOCAL_SOURCE_DIR"/. "$staged_bundle"/
    else
        echo "Downloading from $REPO_URL (ref: $INSTALLER_REF) ..."
        git clone --depth 1 --filter=blob:none --sparse --branch "$INSTALLER_REF" "$REPO_URL" "$TRANSACTION_ROOT/repo" 2>/dev/null
        (cd "$TRANSACTION_ROOT/repo" && git sparse-checkout set "$SKILLS_SUBPATH" 2>/dev/null)
        if [ ! -d "$TRANSACTION_ROOT/repo/$SKILLS_SUBPATH" ]; then
            echo "Error: failed to download skill files. Existing installation was not changed."
            exit 1
        fi
        cp -R "$TRANSACTION_ROOT/repo/$SKILLS_SUBPATH"/. "$staged_bundle"/
    fi

    if ! bundle_is_complete "$staged_bundle"; then
        echo "Error: staged bundle is incomplete. Existing installation was not changed."
        exit 1
    fi
}

replace_bundle() {
    local staged_bundle="$TRANSACTION_ROOT/new"
    local backup_bundle="$TRANSACTION_ROOT/backup"
    local skill
    local -a backed_up=()
    local -a installed=()
    mkdir -p "$backup_bundle"

    for skill in "${BUNDLED_SKILLS[@]}"; do
        if [ -e "$TARGET_SKILLS_DIR/$skill" ]; then
            if ! mv "$TARGET_SKILLS_DIR/$skill" "$backup_bundle/$skill"; then
                echo "Error: could not stage the existing '$skill' installation for replacement."
                exit 1
            fi
            backed_up+=("$skill")
        fi
    done

    for skill in "${BUNDLED_SKILLS[@]}"; do
        if ! mv "$staged_bundle/$skill" "$TARGET_SKILLS_DIR/$skill"; then
            echo "Error: replacement failed while installing '$skill'; restoring the previous bundle."
            local installed_skill
            for installed_skill in "${installed[@]}"; do
                rm -rf "$TARGET_SKILLS_DIR/$installed_skill"
            done
            local backup_skill
            for backup_skill in "${backed_up[@]}"; do
                if [ -e "$backup_bundle/$backup_skill" ]; then
                    mv "$backup_bundle/$backup_skill" "$TARGET_SKILLS_DIR/$backup_skill"
                fi
            done
            exit 1
        fi
        installed+=("$skill")
    done
}

local_version="$(get_local_version)"
source_version="$(get_source_version || true)"

if bundle_has_existing_target; then
    if [ -n "$source_version" ] && [ "$local_version" = "$source_version" ] && bundle_is_complete "$TARGET_SKILLS_DIR"; then
        echo "Bundled skills are already up to date for $PLATFORM_NAME (v$local_version)."
        exit 0
    fi

    if [ -z "$source_version" ]; then
        echo "Warning: could not determine source version. Existing installation was not changed."
    elif [ "$local_version" = "$source_version" ]; then
        echo "Bundled skills v$local_version are incomplete or damaged; repair is required."
    else
        echo "Install/update required for $PLATFORM_NAME: v${local_version:-unknown} -> v$source_version"
    fi
    confirm_install || { echo "Aborted."; exit 0; }
fi

stage_bundle
replace_bundle
installed_version="$(get_local_version)"
echo "Installed bundled skills v${installed_version:-unknown} to $TARGET_SKILLS_DIR"
