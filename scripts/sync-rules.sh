#!/usr/bin/env bash
# Sync agency rules into an existing project.
# Pulls the latest AGENTS.md, CLAUDE.md, and .cursor/rules/ from the template
# repo, preserving project-specific sections in AGENTS.md.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/thezpack/agency-rules-template/main/scripts/sync-rules.sh | bash
#
# Or, from an existing clone of the template:
#   ./scripts/sync-rules.sh /path/to/your/project

set -euo pipefail

TEMPLATE_RAW="https://raw.githubusercontent.com/thezpack/agency-rules-template/main"
TARGET_DIR="${1:-$PWD}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "❌ Target directory does not exist: $TARGET_DIR"
  exit 1
fi

cd "$TARGET_DIR"

if [ ! -d .git ]; then
  echo "⚠️  $TARGET_DIR is not a git repo. Continue anyway? (y/N)"
  read -r answer
  [[ "$answer" =~ ^[Yy]$ ]] || exit 0
fi

echo "Syncing agency rules into $TARGET_DIR"
echo

# ─── AGENTS.md — preserve project-specific sections ─────────────────────────
# Project-specific sections are delimited by these markers in the template:
#   ## Project-Specific Context   (and everything under it until the next H2)
#   ## Changelog                  (and everything under it until the next H2)
# On sync, we:
#   1. extract those sections from the existing AGENTS.md
#   2. fetch the new template AGENTS.md
#   3. replace the corresponding sections in the new file with the preserved content

if [ -f AGENTS.md ]; then
  echo "📄 Updating AGENTS.md (preserving project-specific sections)..."

  # Extract preserved sections from existing file
  preserved_context=$(awk '/^## Project-Specific Context/,/^## [^P]/' AGENTS.md | sed '$d')
  preserved_changelog=$(awk '/^## Changelog/,0' AGENTS.md)

  # Fetch new template
  curl -fsSL "$TEMPLATE_RAW/AGENTS.md" -o AGENTS.md.new

  # Splice preserved sections back in
  awk -v ctx="$preserved_context" -v log="$preserved_changelog" '
    /^## Project-Specific Context/ { print ctx; skip=1; next }
    /^## Changelog/ { print log; skip=2; next }
    skip==1 && /^## [^P]/ { skip=0 }
    skip==2 { next }
    skip==0 { print }
  ' AGENTS.md.new > AGENTS.md

  rm AGENTS.md.new
else
  echo "📄 Creating AGENTS.md from template..."
  curl -fsSL "$TEMPLATE_RAW/AGENTS.md" -o AGENTS.md
fi

# ─── CLAUDE.md — always overwrite (it's just a pointer) ─────────────────────
echo "🤖 Updating CLAUDE.md pointer..."
curl -fsSL "$TEMPLATE_RAW/CLAUDE.md" -o CLAUDE.md

# ─── .cursor/rules/ — refresh all template rules ────────────────────────────
echo "🎯 Updating .cursor/rules/..."
mkdir -p .cursor/rules

# List of rule files in the template
rules=(
  "project.mdc"
  "design-impeccable.mdc"
  "design-polish.mdc"
  "design-typeset.mdc"
  "design-layout.mdc"
  "design-audit.mdc"
  "design-critique.mdc"
  "design-clarify.mdc"
  "design-colorize.mdc"
  "design-distill.mdc"
  "design-adapt.mdc"
  "design-delight.mdc"
  "design-optimize.mdc"
  "design-animate.mdc"
)

for f in "${rules[@]}"; do
  if curl -fsSL "$TEMPLATE_RAW/.cursor/rules/$f" -o ".cursor/rules/$f" 2>/dev/null; then
    echo "   ✓ $f"
  else
    echo "   ⚠️  skipped $f (not in template yet)"
  fi
done

# ─── scripts/setup-dev-env.sh — refresh ─────────────────────────────────────
mkdir -p scripts
curl -fsSL "$TEMPLATE_RAW/scripts/setup-dev-env.sh" -o scripts/setup-dev-env.sh
chmod +x scripts/setup-dev-env.sh

echo
echo "✅ Sync complete."
echo
echo "Review the changes:"
echo "   git diff"
echo
echo "Then commit:"
echo "   git add AGENTS.md CLAUDE.md .cursor/rules scripts/setup-dev-env.sh"
echo "   git commit -m 'chore: sync agency rules from template'"
