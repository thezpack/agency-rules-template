#!/usr/bin/env bash
# One-time setup for new teammates on any Revex project.
# Installs agency-standard Claude Code skills globally into ~/.claude/skills/.
# Safe to re-run — skills add is idempotent.

set -euo pipefail

# ─── Check prerequisites ─────────────────────────────────────────────────────
if ! command -v npx >/dev/null 2>&1; then
  echo "❌ npx not found. Install Node.js first: https://nodejs.org"
  exit 1
fi

echo "Installing agency-standard Claude Code skills..."
echo

# The agency design skills (Impeccable) were removed on 2026-10-23; Sura is
# rewriting the design rules from scratch.

# ─── Add agency-standard skills below ────────────────────────────────────────
# Example:
# echo "🔍 Installing X skill..."
# npx -y skills add owner/skill-name

echo
echo "✅ Done."
echo
echo "Skills are installed globally at ~/.claude/skills/ and work in every project."
echo "Restart Claude Code to pick up newly installed skills."
