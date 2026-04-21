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

# ─── Design skill pack (Impeccable by Paul Bakaus) ───────────────────────────
# This is a bundle of design-quality skills: impeccable, polish, typeset,
# layout, colorize, clarify, audit, critique, distill, adapt, delight,
# optimize, animate, and others. See https://impeccable.style
echo "📐 Installing Impeccable design skills..."
npx -y skills add pbakaus/impeccable

# ─── Add additional agency-standard skills below ─────────────────────────────
# Example:
# echo "🔍 Installing X skill..."
# npx -y skills add owner/skill-name

echo
echo "✅ Done."
echo
echo "Skills are installed globally at ~/.claude/skills/ and work in every project."
echo "Restart Claude Code to pick up newly installed skills."
echo
echo "Cursor users: design skill rules are already in .cursor/rules/ and load automatically."
