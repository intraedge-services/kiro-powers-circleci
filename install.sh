#!/bin/bash
# Install kiro-powers-circleci into a Kiro workspace
#
# Usage:
#   cd /path/to/your-project
#   /path/to/kiro-powers-circleci/install.sh
#
# Or from the power directory:
#   ./install.sh /path/to/your-project

set -e

# Determine target workspace
TARGET_WORKSPACE="${1:-.}"

# Resolve to absolute path
TARGET_WORKSPACE="$(cd "$TARGET_WORKSPACE" && pwd)"

echo "Installing kiro-powers-circleci into: $TARGET_WORKSPACE"

# Get the directory where this script lives
POWER_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create required directories
mkdir -p "$TARGET_WORKSPACE/.kiro/settings"
mkdir -p "$TARGET_WORKSPACE/.kiro/powers/kiro-powers-circleci"

# Copy power files
echo "→ Copying power files to .kiro/powers/kiro-powers-circleci/"
cp "$POWER_DIR/POWER.md" "$TARGET_WORKSPACE/.kiro/powers/kiro-powers-circleci/"
cp "$POWER_DIR/package.json" "$TARGET_WORKSPACE/.kiro/powers/kiro-powers-circleci/"
cp -r "$POWER_DIR/steering" "$TARGET_WORKSPACE/.kiro/powers/kiro-powers-circleci/"
cp -r "$POWER_DIR/hooks" "$TARGET_WORKSPACE/.kiro/powers/kiro-powers-circleci/"
cp -r "$POWER_DIR/templates" "$TARGET_WORKSPACE/.kiro/powers/kiro-powers-circleci/"

# Install MCP config
if [ -f "$TARGET_WORKSPACE/.kiro/settings/mcp.json" ]; then
  echo ""
  echo "⚠️  .kiro/settings/mcp.json already exists."
  echo "   Please manually merge the circleci server config from:"
  echo "   $POWER_DIR/config/mcp.json"
  echo ""
else
  echo "→ Creating .kiro/settings/mcp.json"
  cp "$POWER_DIR/config/mcp.json" "$TARGET_WORKSPACE/.kiro/settings/mcp.json"
fi

# Check for CIRCLECI_TOKEN
echo ""
if [ -z "$CIRCLECI_TOKEN" ]; then
  echo "⚠️  CIRCLECI_TOKEN is not set in your environment."
  echo "   The MCP server will start but API calls will fail."
  echo ""
  echo "   To fix, add to your ~/.zshrc or ~/.bashrc:"
  echo "     export CIRCLECI_TOKEN=\"your-token-here\""
  echo ""
  echo "   Get a token at: https://app.circleci.com/settings/user/tokens"
else
  echo "✓ CIRCLECI_TOKEN is set"
fi

echo ""
echo "✓ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Ensure CIRCLECI_TOKEN is set (see above)"
echo "  2. Reload Kiro (or reconnect MCP servers via Command Palette)"
echo "  3. Ask Kiro: \"List my followed CircleCI projects\""
