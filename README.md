# Revex Agency Rules Template

Canonical rules, AI agent instructions, and design-skill guidance that live in **every Revex project**. Works across Claude Code and Cursor. Platform-agnostic — React web, React Native, Node services all use the same template with tagged sections.

## What's inside

```
.
├── AGENTS.md                     Canonical rule file. Edit this; everything else points to it.
├── CLAUDE.md                     Pointer for Claude Code.
├── .cursor/
│   └── rules/
│       ├── project.mdc           Pointer for Cursor.
│       └── design-*.mdc          Per-skill rules mirrored from ~/.claude/skills/
└── scripts/
    ├── setup-dev-env.sh          One-time teammate setup (installs Claude Code skills).
    └── sync-rules.sh             Pulls latest template into an existing project.
```

## For new projects (one-liner)

Scaffold your project however you want (`create-next-app`, `create-expo-app`, `create-vite`, whatever), then from inside the project run:

```bash
curl -fsSL https://raw.githubusercontent.com/thezpack/agency-rules-template/main/scripts/sync-rules.sh | bash
```

That single command:

- Drops `AGENTS.md`, `CLAUDE.md`, and `.cursor/rules/*.mdc` into the project
- Installs `scripts/sync-rules.sh` and `scripts/setup-dev-env.sh`
- Updates `.gitignore` so `.cursor/rules/` stays tracked but transient `.cursor/*` state doesn't

Then:

```bash
# Fill in the Identity section of AGENTS.md (Platform, Stack, Deployed to, etc.)
./scripts/setup-dev-env.sh   # one-time per machine — installs design skills for Claude Code
git add AGENTS.md CLAUDE.md .cursor/rules scripts .gitignore
git commit -m "chore: install agency rules"
```

## For new projects (GitHub template alternative)

This repo is also marked as a **GitHub template** if you prefer to start with the template files already in place:

```bash
gh repo create <org>/<new-project> --template thezpack/agency-rules-template --private
```

Or click "Use this template" on GitHub. Then scaffold your framework inside that clone (`npx create-next-app .`, etc.).

## For teammates joining a project

Every Revex project has these files. The AI reads them automatically. Your one-time setup:

```bash
# Clone the project (rules come with it)
git clone <project-repo>
cd <project-repo>

# Install agency-standard design skills globally (one-time per machine, not per-project)
./scripts/setup-dev-env.sh

# Restart Claude Code to pick up skills
```

**Cursor users:** no setup required — the design rules in `.cursor/rules/` load automatically.

## How the pieces fit together

| File | Read by | Purpose |
|---|---|---|
| `AGENTS.md` | Humans + AI (both tools) | The actual rules. Source of truth. |
| `CLAUDE.md` | Claude Code (auto-loaded) | Three lines: "see AGENTS.md" |
| `.cursor/rules/project.mdc` | Cursor (auto-loaded, always) | Pointer to AGENTS.md |
| `.cursor/rules/design-*.mdc` | Cursor (auto-loaded when relevant) | Design-skill guidance for Cursor users |
| `~/.claude/skills/` | Claude Code (global) | Actual design skills — installed via setup script |

This split means Claude Code and Cursor users get equivalent behavior without duplicating everything in every repo.

## Updating rules across all existing projects

When agency-wide rules evolve (e.g. we adopt a new default framework, or add a PR requirement):

1. Update `AGENTS.md` or the relevant file here.
2. Commit and push to `main`.
3. Each project runs `./scripts/sync-rules.sh` when ready to pull the latest. The sync script **preserves** each project's `Project-Specific Context` and `Changelog` sections while refreshing everything else.

## Adding a new design skill

1. `npx skills add <owner>/<skill>` locally to preview.
2. Add the install command to `scripts/setup-dev-env.sh`.
3. Generate a Cursor mirror by adding an entry to the skill list in the generator script (see commit history) and regenerating `.cursor/rules/design-<name>.mdc`.
4. Add a row to the **Available Design Skills** table in `AGENTS.md`.
5. Commit + teammates run `sync-rules.sh` in their projects.

## Why `AGENTS.md` and not `CLAUDE.md` as the source of truth?

`AGENTS.md` is becoming the cross-tool standard (see agents.md). Keeping the canonical file at the neutral name means:

- Cursor, Claude Code, future AI tools can all read the same file.
- No tool-specific lock-in.
- When AI updates rules, it updates one file — not three copies.
