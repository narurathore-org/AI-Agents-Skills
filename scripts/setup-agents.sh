#!/bin/bash
# Sets up agents from this repo for use globally or in a target project.
#
# Usage:
#   ./scripts/setup-agents.sh                  — sync Claude agents to ~/.claude/agents/
#   ./scripts/setup-agents.sh --project        — also copy .agents/ into current directory
#   ./scripts/setup-agents.sh --project <path> — copy .agents/ into <path>

REPO="$(cd "$(dirname "$0")/.." && pwd)"

# Sync Claude agent wrappers globally
cp "$REPO/.claude/agents/"*.md ~/.claude/agents/
echo "✓ Claude agents synced to ~/.claude/agents/"

# Optionally set up shared prompts + skills in a project
if [ "$1" = "--project" ]; then
  TARGET="${2:-$(pwd)}"
  cp -r "$REPO/.agents/" "$TARGET/"
  echo "✓ Shared prompts and skills copied to $TARGET/.agents/"
fi
