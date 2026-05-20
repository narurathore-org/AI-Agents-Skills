#!/bin/bash
# Sets up agents from this repo for use globally or in a target project.
#
# Usage:
#   ./scripts/setup-agents.sh                  — symlink ~/.claude/agents -> repo (live sync)
#   ./scripts/setup-agents.sh --project        — also copy .agents/ into current directory
#   ./scripts/setup-agents.sh --project <path> — copy .agents/ into <path>

set -e

REPO="$(cd "$(dirname "$0")/.." && pwd)"
AGENTS_SRC="$REPO/.claude/agents"
AGENTS_DST="$HOME/.claude/agents"

mkdir -p "$HOME/.claude"

# Symlink ~/.claude/agents -> repo/.claude/agents for live bidirectional sync
if [ -L "$AGENTS_DST" ]; then
  current_target="$(readlink "$AGENTS_DST")"
  if [ "$current_target" = "$AGENTS_SRC" ]; then
    echo "✓ ~/.claude/agents already symlinked to $AGENTS_SRC"
  else
    echo "⚠ ~/.claude/agents symlinked to a different path: $current_target"
    echo "  Remove it manually and re-run if you want to re-link to this repo."
    exit 1
  fi
elif [ -d "$AGENTS_DST" ]; then
  echo "⚠ ~/.claude/agents exists as a real directory."
  echo "  Move/back up any agents you want to keep, then 'rm -rf ~/.claude/agents' and re-run."
  exit 1
else
  ln -s "$AGENTS_SRC" "$AGENTS_DST"
  echo "✓ Symlinked ~/.claude/agents -> $AGENTS_SRC"
fi

# Optionally set up shared prompts + skills in a project
if [ "$1" = "--project" ]; then
  TARGET="${2:-$(pwd)}"
  cp -r "$REPO/.agents/" "$TARGET/"
  echo "✓ Shared prompts and skills copied to $TARGET/.agents/"
fi
