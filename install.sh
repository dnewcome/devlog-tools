#!/usr/bin/env bash
# devlog-tools install script
# Vendors devlog-tools scripts into the current project at a specific tag.
#
# Usage (from inside your project repo):
#   bash <(curl -fsSL https://raw.githubusercontent.com/dnewcome/devlog-tools/main/install.sh) [--tag v1.0]
#
# Or if you have it locally:
#   bash path/to/devlog-tools/install.sh [--tag v1.0]
#
# Records the installed version in .project.toml under [devlog].
# Re-run with a new --tag to upgrade. Local edits to scripts/ are overwritten on upgrade.

set -euo pipefail

REPO="https://github.com/dnewcome/devlog-tools"
TAG="main"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) TAG="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"
COMMANDS_DIR="$PROJECT_ROOT/.claude/commands"
TOML="$PROJECT_ROOT/.project.toml"

echo "Installing devlog-tools@${TAG} into $(basename "$PROJECT_ROOT")..."

# Download and extract tarball
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if [[ "$TAG" == "main" ]]; then
  TARBALL_URL="$REPO/archive/refs/heads/main.tar.gz"
else
  TARBALL_URL="$REPO/archive/refs/tags/${TAG}.tar.gz"
fi

echo "  Fetching $TARBALL_URL..."
curl -fsSL "$TARBALL_URL" | tar xz -C "$TMP"
SRC=$(ls "$TMP")  # e.g. devlog-tools-1.0 or devlog-tools-main

# Copy scripts
mkdir -p "$SCRIPTS_DIR" "$COMMANDS_DIR"
cp "$TMP/$SRC/scripts/"*.sh "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR/"*.sh
echo "  Copied scripts/ ✓"

# Copy Claude skill
cp "$TMP/$SRC/commands/devsnap.md" "$COMMANDS_DIR/"
echo "  Copied .claude/commands/devsnap.md ✓"

# Copy devlog/ skeleton if not already present
if [[ ! -d "$PROJECT_ROOT/devlog" ]]; then
  mkdir -p "$PROJECT_ROOT/devlog/assets"
  touch "$PROJECT_ROOT/devlog/assets/.gitkeep"
  echo "  Created devlog/ ✓"
fi

# Update .project.toml with installed version
if [[ -f "$TOML" ]]; then
  # Remove existing [devlog] section if present
  python3 - "$TOML" "$TAG" "$REPO" <<'PY'
import sys, re

path, tag, repo = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    content = f.read()

# Remove existing [devlog] block
content = re.sub(r'\[devlog\][^\[]*', '', content).rstrip()

content += f'\n\n[devlog]\nversion = "{tag}"\nsource = "{repo}"\n'
with open(path, 'w') as f:
    f.write(content)
PY
  echo "  Updated .project.toml with version=${TAG} ✓"
else
  echo "  Note: no .project.toml found — create one to record the installed version"
fi

# Install git hook
bash "$SCRIPTS_DIR/install-hooks.sh"

echo ""
echo "✅ devlog-tools@${TAG} installed."
echo "   To take a snapshot: git commit -m 'your message [snap]'"
echo "   To preview devlog:  bash scripts/devlog-preview.sh --open"
echo "   To use /devsnap:    open Claude Code in this directory"
