#!/bin/bash
# install.sh - Bootstrap script for running Claude Code Bedrock setup from GitHub
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/ChadDahlgren/claude-code-bedrock/main/setup/install.sh)
#        bash <(curl -fsSL ...) --tui   # For TUI version

set -euo pipefail

REPO_BASE="https://raw.githubusercontent.com/ChadDahlgren/claude-code-bedrock/main/setup"
TEMP_DIR=""

# Cleanup function
cleanup() {
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}

trap cleanup EXIT

# Create temp directory
TEMP_DIR=$(mktemp -d)
mkdir -p "$TEMP_DIR/lib"

echo "Downloading setup scripts..."

# Download the required files
curl -fsSL "$REPO_BASE/lib/core.sh" -o "$TEMP_DIR/lib/core.sh"
curl -fsSL "$REPO_BASE/setup-claude-bedrock.sh" -o "$TEMP_DIR/setup-claude-bedrock.sh"
curl -fsSL "$REPO_BASE/setup-claude-bedrock-tui.sh" -o "$TEMP_DIR/setup-claude-bedrock-tui.sh"

chmod +x "$TEMP_DIR/setup-claude-bedrock.sh"
chmod +x "$TEMP_DIR/setup-claude-bedrock-tui.sh"

# Determine which script to run
if [[ "${1:-}" == "--tui" ]]; then
  shift
  exec "$TEMP_DIR/setup-claude-bedrock-tui.sh" "$@"
else
  exec "$TEMP_DIR/setup-claude-bedrock.sh" "$@"
fi
