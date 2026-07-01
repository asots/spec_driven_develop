#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="spec-driven-develop"
REPO_URL="https://github.com/zhu1090093659/spec_driven_develop"
RAW_URL="https://raw.githubusercontent.com/zhu1090093659/spec_driven_develop/main"
OPENCODE_HOME="${OPENCODE_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}"
TARGET_VENDOR_DIR="$OPENCODE_HOME/vendor/$PLUGIN_NAME"
TARGET_PLUGIN_DIR="$OPENCODE_HOME/plugins"
TARGET_PLUGIN_FILE="$TARGET_PLUGIN_DIR/$PLUGIN_NAME.js"
PLUGIN_SUBPATH="plugins/spec-driven-develop"
SKILL_SUBPATH="$PLUGIN_SUBPATH/skills/$PLUGIN_NAME"

extract_version() {
    grep -m1 '^version:' "$1" 2>/dev/null | sed 's/version:[[:space:]]*//'
}

get_local_version() {
    local skill_file="$TARGET_VENDOR_DIR/skills/$PLUGIN_NAME/SKILL.md"
    if [ -f "$skill_file" ]; then
        extract_version "$skill_file"
    fi
}

get_source_version() {
    local local_skill
    local_skill="$(dirname "$0")/../$SKILL_SUBPATH/SKILL.md"
    if [ -f "$local_skill" ] 2>/dev/null; then
        extract_version "$local_skill"
    else
        curl -sL "$RAW_URL/$SKILL_SUBPATH/SKILL.md" | grep -m1 '^version:' | sed 's/version:[[:space:]]*//'
    fi
}

write_loader() {
    mkdir -p "$TARGET_PLUGIN_DIR"
    printf '%s\n' \
        'export { default } from "../vendor/spec-driven-develop/opencode-plugin.js"' \
        'export * from "../vendor/spec-driven-develop/opencode-plugin.js"' \
        > "$TARGET_PLUGIN_FILE"
}

install_from_local() {
    local source_dir
    source_dir="$(cd "$(dirname "$0")/../$PLUGIN_SUBPATH" && pwd)"
    if [ ! -d "$source_dir" ]; then
        echo "Error: source directory not found: $source_dir"
        exit 1
    fi
    cp -r "$source_dir" "$TARGET_VENDOR_DIR"
}

install_from_remote() {
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' EXIT

    echo "Downloading from $REPO_URL ..."
    git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$tmp_dir/repo" 2>/dev/null
    (cd "$tmp_dir/repo" && git sparse-checkout set "$PLUGIN_SUBPATH" 2>/dev/null)

    if [ ! -d "$tmp_dir/repo/$PLUGIN_SUBPATH" ]; then
        echo "Error: failed to download plugin files."
        exit 1
    fi
    cp -r "$tmp_dir/repo/$PLUGIN_SUBPATH" "$TARGET_VENDOR_DIR"
}

do_install() {
    mkdir -p "$(dirname "$TARGET_VENDOR_DIR")" "$TARGET_PLUGIN_DIR"
    if [ -f "$(dirname "$0")/../$PLUGIN_SUBPATH/opencode-plugin.js" ] 2>/dev/null; then
        install_from_local
    else
        install_from_remote
    fi
    write_loader
}

if [ -d "$TARGET_VENDOR_DIR" ]; then
    local_version=$(get_local_version)
    source_version=$(get_source_version)

    if [ -z "$source_version" ]; then
        echo "Warning: could not determine source version."
        read -p "Re-install '$PLUGIN_NAME' (local: v${local_version:-unknown})? [y/N] " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
    elif [ "$local_version" = "$source_version" ]; then
        write_loader
        echo "'$PLUGIN_NAME' is already up to date (v$local_version)."
        echo "OpenCode will auto-load $TARGET_PLUGIN_FILE on restart."
        exit 0
    else
        echo "Update available: v${local_version:-unknown} -> v$source_version"
        read -p "Update? [y/N] " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
    fi
    rm -rf "$TARGET_VENDOR_DIR"
fi

do_install

installed_version=$(get_local_version)
echo "Installed '$PLUGIN_NAME' v${installed_version:-unknown} to $TARGET_VENDOR_DIR"
echo "OpenCode will auto-load $TARGET_PLUGIN_FILE on restart."
echo "Quit and restart OpenCode to activate the plugin."
