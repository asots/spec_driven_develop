#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="spec-driven-develop"
INSTALLER_REF="${SPEC_DRIVEN_INSTALL_REF:-main}"
REPO_URL="https://github.com/asots/spec_driven_develop"
OPENCODE_HOME="${OPENCODE_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}"
TARGET_VENDOR_DIR="$OPENCODE_HOME/vendor/$PLUGIN_NAME"
TARGET_PLUGIN_DIR="$OPENCODE_HOME/plugins"
TARGET_PLUGIN_FILE="$TARGET_PLUGIN_DIR/$PLUGIN_NAME.js"
PLUGIN_SUBPATH="plugins/spec-driven-develop"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_SOURCE_DIR="${SPEC_DRIVEN_PLUGIN_SOURCE_DIR:-$SCRIPT_DIR/../$PLUGIN_SUBPATH}"
TRANSACTION_ROOT=""

cleanup_installer() {
    if [ -n "$TRANSACTION_ROOT" ] && [ -d "$TRANSACTION_ROOT" ]; then
        rm -rf "$TRANSACTION_ROOT"
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

get_version() {
    local root="$1"
    extract_version "$root/skills/$PLUGIN_NAME/SKILL.md"
}

plugin_is_complete() {
    local root="$1"
    [ -s "$root/opencode-plugin.js" ] || return 1
    [ -s "$root/skills/spec-driven-develop/SKILL.md" ] || return 1
    [ -s "$root/skills/deep-discuss/SKILL.md" ] || return 1
    [ -s "$root/skills/review-spd/SKILL.md" ] || return 1
    [ -s "$root/skills/review-spd/references/output-format.md" ] || return 1
}

plugin_matches_source() {
    local source_root="$1"
    local target_root="$2"
    local source_file
    while IFS= read -r -d '' source_file; do
        local relative_path="${source_file#"$source_root"/}"
        [ -f "$target_root/$relative_path" ] || return 1
        cmp -s "$source_file" "$target_root/$relative_path" || return 1
    done < <(find "$source_root" -type f -print0)
}

stage_plugin() {
    mkdir -p "$OPENCODE_HOME/vendor" "$TARGET_PLUGIN_DIR"
    TRANSACTION_ROOT="$(mktemp -d "$OPENCODE_HOME/vendor/.spec-driven-install.XXXXXX")"
    local staged_plugin="$TRANSACTION_ROOT/new"

    if [ -f "$LOCAL_SOURCE_DIR/opencode-plugin.js" ]; then
        cp -R "$LOCAL_SOURCE_DIR" "$staged_plugin"
    else
        echo "Downloading from $REPO_URL (ref: $INSTALLER_REF) ..."
        git clone --depth 1 --filter=blob:none --sparse --branch "$INSTALLER_REF" "$REPO_URL" "$TRANSACTION_ROOT/repo" 2>/dev/null
        (cd "$TRANSACTION_ROOT/repo" && git sparse-checkout set "$PLUGIN_SUBPATH" 2>/dev/null)
        if [ ! -d "$TRANSACTION_ROOT/repo/$PLUGIN_SUBPATH" ]; then
            echo "Error: failed to download plugin files. Existing installation was not changed."
            exit 1
        fi
        cp -R "$TRANSACTION_ROOT/repo/$PLUGIN_SUBPATH" "$staged_plugin"
    fi

    if ! plugin_is_complete "$staged_plugin"; then
        echo "Error: staged plugin is incomplete. Existing installation was not changed."
        exit 1
    fi
}

write_loader() {
    mkdir -p "$TARGET_PLUGIN_DIR"
    local loader_tmp
    loader_tmp="$(mktemp "$TARGET_PLUGIN_DIR/.spec-driven-loader.XXXXXX")"
    printf '%s\n' \
        'export { default } from "../vendor/spec-driven-develop/opencode-plugin.js"' \
        'export * from "../vendor/spec-driven-develop/opencode-plugin.js"' \
        > "$loader_tmp"
    mv "$loader_tmp" "$TARGET_PLUGIN_FILE"
}

confirm_install() {
    if [ "${SPEC_DRIVEN_INSTALL_YES:-0}" = "1" ]; then
        return 0
    fi
    read -p "Install/repair '$PLUGIN_NAME'? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

replace_plugin() {
    local staged_plugin="$TRANSACTION_ROOT/new"
    local backup_plugin="$TRANSACTION_ROOT/backup"

    if [ -e "$TARGET_VENDOR_DIR" ]; then
        mv "$TARGET_VENDOR_DIR" "$backup_plugin"
    fi

    if ! mv "$staged_plugin" "$TARGET_VENDOR_DIR"; then
        echo "Error: plugin replacement failed; restoring the previous installation."
        if [ -e "$backup_plugin" ]; then
            mv "$backup_plugin" "$TARGET_VENDOR_DIR"
        fi
        exit 1
    fi
}

stage_plugin
source_version="$(get_version "$TRANSACTION_ROOT/new")"
local_version=""
if [ -d "$TARGET_VENDOR_DIR" ]; then
    local_version="$(get_version "$TARGET_VENDOR_DIR")"
    if [ "$local_version" = "$source_version" ] && plugin_matches_source "$TRANSACTION_ROOT/new" "$TARGET_VENDOR_DIR"; then
        write_loader
        echo "'$PLUGIN_NAME' is already up to date (v$local_version)."
        echo "OpenCode will auto-load $TARGET_PLUGIN_FILE on restart."
        exit 0
    fi

    if [ "$local_version" = "$source_version" ]; then
        echo "Plugin v$local_version is incomplete, damaged, or locally divergent; repair is required."
    else
        echo "Update available: v${local_version:-unknown} -> v$source_version"
    fi
    confirm_install || { echo "Aborted."; exit 0; }
fi

replace_plugin
write_loader
installed_version="$(get_version "$TARGET_VENDOR_DIR")"
echo "Installed '$PLUGIN_NAME' v${installed_version:-unknown} to $TARGET_VENDOR_DIR"
echo "OpenCode will auto-load $TARGET_PLUGIN_FILE on restart."
echo "Quit and restart OpenCode to activate the plugin."
