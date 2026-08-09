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

  # Fetch new template alongside the existing file so we can splice with Node.
  curl -fsSL "$TEMPLATE_RAW/AGENTS.md" -o AGENTS.md.new

  # Splice in Node. Avoids the BSD-vs-GNU awk multi-line `-v` pitfall that
  # silently destroyed AGENTS.md on macOS before this rewrite.
  node --input-type=module -e '
    import { readFileSync, writeFileSync } from "node:fs";

    const oldContent = readFileSync("AGENTS.md", "utf-8");
    const newContent = readFileSync("AGENTS.md.new", "utf-8");

    // Extract a section from "## Heading" up to (but not including) the next "## " heading.
    function extract(text, headingRegex) {
      const m = text.match(headingRegex);
      if (!m) return null;
      const start = m.index;
      const rest = text.slice(start + m[0].length);
      const nextHeader = rest.match(/\n## /);
      const end = nextHeader ? start + m[0].length + nextHeader.index : text.length;
      return text.slice(start, end).replace(/\s*$/, "");
    }

    // Replace a section in `text` with `replacement`. If the section is missing
    // from `text`, append at the end. If `replacement` is null/empty, leave the
    // template section alone.
    function replace(text, headingRegex, replacement) {
      if (!replacement) return text;
      const m = text.match(headingRegex);
      if (!m) return text.trimEnd() + "\n\n" + replacement + "\n";
      const start = m.index;
      const rest = text.slice(start + m[0].length);
      const nextHeader = rest.match(/\n## /);
      const end = nextHeader ? start + m[0].length + nextHeader.index : text.length;
      return text.slice(0, start) + replacement + (end < text.length ? "\n\n" + text.slice(end).trimStart() : "\n");
    }

    // Identity is per-project metadata (project name, surfaces, tier, repo,
    // linear workspace, supabase ref). Filled in once at install time and
    // never reverted on sync. If the template gains a new Identity field, the
    // project will need to add it manually — but that beats wiping every
    // project'\''s filled values on every sync, which was the pre-2026-06-03
    // behavior.
    const HEAD_ID  = /^## Identity\b.*$/m;
    const HEAD_CTX = /^## Project-Specific Context\b.*$/m;
    const HEAD_LOG = /^## Changelog\b.*$/m;

    const preservedId  = extract(oldContent, HEAD_ID);
    const preservedCtx = extract(oldContent, HEAD_CTX);
    const preservedLog = extract(oldContent, HEAD_LOG);

    let merged = newContent;
    merged = replace(merged, HEAD_ID,  preservedId);
    merged = replace(merged, HEAD_CTX, preservedCtx);
    merged = replace(merged, HEAD_LOG, preservedLog);

    writeFileSync("AGENTS.md", merged);
    console.log(`   ✓ Spliced (preserved ${preservedId?.length ?? 0} chars identity, ${preservedCtx?.length ?? 0} chars context, ${preservedLog?.length ?? 0} chars changelog)`);
  '

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
  "pull-requests.mdc"
  "task-logging.mdc"
)

for f in "${rules[@]}"; do
  if curl -fsSL "$TEMPLATE_RAW/.cursor/rules/$f" -o ".cursor/rules/$f" 2>/dev/null; then
    echo "   ✓ $f"
  else
    echo "   ⚠️  skipped $f (not in template yet)"
  fi
done

# ─── .github/ — PR template + workflows + scripts ──────────────────────────
# Three layers of defense for PR descriptions:
#   1. PULL_REQUEST_TEMPLATE.md pre-fills the body box at PR creation
#   2. auto-pr-body.yml workflow detects empty bodies post-creation and
#      auto-generates from the diff + AGENTS.md (requires ANTHROPIC_API_KEY
#      as a repo secret)
#   3. The Cursor pull-requests.mdc rule reminds the AI to fill bodies when
#      it has the chance
echo "📄 Updating .github/..."
mkdir -p .github .github/workflows .github/scripts
curl -fsSL "$TEMPLATE_RAW/.github/PULL_REQUEST_TEMPLATE.md" -o .github/PULL_REQUEST_TEMPLATE.md
echo "   ✓ PULL_REQUEST_TEMPLATE.md"
curl -fsSL "$TEMPLATE_RAW/.github/workflows/auto-pr-body.yml" -o .github/workflows/auto-pr-body.yml
echo "   ✓ workflows/auto-pr-body.yml"
curl -fsSL "$TEMPLATE_RAW/.github/scripts/auto-pr-body.mjs" -o .github/scripts/auto-pr-body.mjs
echo "   ✓ scripts/auto-pr-body.mjs"

# ─── Required-CI workflows ─────────────────────────────────────────────────
# Universal gates declared in AGENTS.md → "Required CI Checks".
# typecheck + lint apply to every tier. build + test apply to standard +
# critical and can be deleted in minimal-tier projects (the workflow comments
# say so). linear-link-check keeps PRs tied to a Linear issue so the issue
# auto-transitions on merge; it assumes the `REV-` ticket prefix (see the
# TICKET_PREFIX env var in that file).
# Always overwrite — these files are template-owned, not project-owned. Local
# tweaks belong in a project-specific *.yml alongside, or in
# Project-Specific Context with the rationale.
for wf in typecheck.yml lint.yml build.yml test.yml linear-link-check.yml; do
  curl -fsSL "$TEMPLATE_RAW/.github/workflows/$wf" -o ".github/workflows/$wf"
  echo "   ✓ workflows/$wf"
done

# ─── scripts/ — refresh both setup and sync scripts ─────────────────────────
mkdir -p scripts
curl -fsSL "$TEMPLATE_RAW/scripts/setup-dev-env.sh" -o scripts/setup-dev-env.sh
curl -fsSL "$TEMPLATE_RAW/scripts/sync-rules.sh" -o scripts/sync-rules.sh
curl -fsSL "$TEMPLATE_RAW/scripts/log-task.sh" -o scripts/log-task.sh
chmod +x scripts/setup-dev-env.sh scripts/sync-rules.sh scripts/log-task.sh

# ─── .gitignore — keep cursor rules tracked, ignore rest of .cursor ─────────
# Two negations, not one. Newer projects use the `.cursor/rules/` directory of
# .mdc files, but older ones (and any project set up before that convention)
# carry a flat `.cursor/rules.md`. That flat file matches `.cursor/*` and is NOT
# covered by `!.cursor/rules/`, so omitting the second negation silently ignores
# a project's existing rules file — the exact file this script is meant to keep.
GITIGNORE_BLOCK='# Agency rules template (keep cursor rules tracked)\n.cursor/*\n!.cursor/rules/\n!.cursor/rules.md\n'
if [ -f .gitignore ]; then
  if ! grep -q "^\.cursor/\*" .gitignore; then
    printf "\n$GITIGNORE_BLOCK" >> .gitignore
    echo "📝 Updated .gitignore (keep cursor rules tracked)"
  elif ! grep -q "^!\.cursor/rules\.md" .gitignore; then
    # Block predates the flat-file negation — add just the missing line.
    printf '!.cursor/rules.md\n' >> .gitignore
    echo "📝 Updated .gitignore (added !.cursor/rules.md)"
  fi
else
  printf "$GITIGNORE_BLOCK" > .gitignore
  echo "📝 Created .gitignore"
fi

echo
echo "✅ Rules installed."

# ─── Skills — install agency-standard Claude Code skills globally ───────────
# This makes the one-liner a true one-stop onboarding command: rules + skills.
# Skip with REVEX_SKIP_SKILLS=1 (e.g. in CI, or on machines that only need the
# tracked rule files). The skill install is global + idempotent, not per-repo.
if [ "${REVEX_SKIP_SKILLS:-0}" = "1" ]; then
  echo "⏭️  Skipping skill install (REVEX_SKIP_SKILLS=1)."
else
  echo
  echo "🧠 Installing agency-standard Claude Code skills..."
  if bash scripts/setup-dev-env.sh; then
    :
  else
    echo "   ⚠️  Skill install failed — rerun ./scripts/setup-dev-env.sh manually."
  fi
fi

echo
echo "Next steps:"
echo "  1. Open AGENTS.md and fill in the Identity section (Platform, Stack, Deployed to, etc.)"
echo "  2. Add ANTHROPIC_API_KEY as a repo secret if you want auto-PR-body generation:"
echo "       gh secret set ANTHROPIC_API_KEY --repo \$(git config --get remote.origin.url | sed -E 's|.+github.com[/:]([^/]+/[^.]+).*|\\1|')"
echo "  3. Commit:"
echo "       git add AGENTS.md CLAUDE.md .cursor/rules .github scripts .gitignore"
echo "       git commit -m 'chore: install agency rules'"
echo
echo "To pull future template updates: ./scripts/sync-rules.sh"
