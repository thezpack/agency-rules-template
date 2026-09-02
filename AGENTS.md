# Project Rules

> Canonical rules for this project. Both Claude Code and Cursor load this file on every session.
> Edit here — never in `CLAUDE.md` or `.cursor/rules/project.mdc`, which are pointers.

---

## Identity

- **Agency:** Revex
- **Project name:** `<FILL IN>`
- **Surfaces:** `<[web, mobile] | [web] | [mobile]>` — which surfaces this project ships. A project with only a mobile app has `[mobile]`; a SaaS dashboard is `[web]`; a product with both is `[web, mobile]`.
- **Tier:** `<minimal | standard | critical>` — declares which set of CI checks must be green before merge. See [Required CI Checks](#required-ci-checks) for what each tier mandates. Default is `standard`. Use `critical` for any project with paying customers, public traffic, or revenue impact. Use `minimal` only for prototypes, internal scripts, and Lovable bootstraps.
- **Repo:** `<github.com/.../...>`
- **Linear workspace:** `<linear.app/...>`
- **Supabase project ref:** `<FILL IN — e.g. abcdefghijklmn>` (from Supabase dashboard URL)

**Agency-standard stack** (inherited — override in this file only with a concrete reason):
- **Web:** TypeScript + Next.js (App Router) + Tailwind + shadcn/ui, deployed to Vercel
- **Mobile:** TypeScript + Expo (managed) + Expo Router + NativeWind, built with EAS
- **Backend (both):** Supabase (Postgres + Auth + Edge Functions + Storage)
- **State & data:** Zustand + TanStack Query
- **Forms & validation:** React Hook Form + Zod

When a rule below is tagged `(Web only)` or `(Mobile only)`, apply only the ones matching the declared Surfaces above and ignore the others. Rules tagged `(Supabase)` apply on both surfaces whenever Supabase is in use.

---

## Before You Write Code

1. Read this entire file.
2. Check `package.json` before assuming a library is available. Never install a dependency without first checking if an existing one covers the use case.
3. Look at nearby files to match conventions before inventing new ones.
4. If a rule here conflicts with the user's current instruction, the user wins — but flag the conflict so they can decide whether to update this file.

---

## AI Agent Rules

- **Never commit** without explicit user approval.
- **Never force-push** to `main` or any shared branch.
- **Never run destructive DB operations** (`DROP`, `TRUNCATE`, `DELETE` without `WHERE`) without explicit confirmation.
- **Never skip hooks** (`--no-verify`, `--no-gpg-sign`) unless the user asks.
- **Prefer editing existing files** over creating new ones. Don't create new files unless the task clearly needs one.
- **Don't proactively create documentation** (`.md`, READMEs) unless asked.
- If a task seems to violate rules in this file, **stop and ask** before proceeding.
- **Rules here are defaults, not laws.** If you find a concrete reason a rule is wrong for this project (deprecated API, better library, new platform constraint), surface the conflict and propose an update rather than silently working around it. Never ignore a rule without flagging.
- When updating this file, add an entry to **Changelog** at the bottom with the date and reason.

---

## Task Logging

Every task must be logged to the Revex brain so the team has visibility into work patterns, durations, and friction. Run twice per user prompt:

```bash
./scripts/log-task.sh start "One-sentence task summary"
# ...do the work...
./scripts/log-task.sh end "One-sentence task summary" "Complications encountered, or 'none'"
```

Rules:
- Run `start` once at the very beginning of every task, before any other work.
- Run `end` once at the very end of every task, immediately before your final response to the user.
- One pair per user request — not per file edit.
- `complications` should be specific. Future sessions read this to avoid the same pitfalls. Examples: `"Circular dependency required lazy dynamic import"`, `"Merge conflict on main"`, or just `"none"` if it went clean.
- Failures are silent — if `REVEX_TASK_LOG_KEY` isn't set or the network fails, the script exits 0 and the task continues. Never block work to retry.
- For abandoned tasks, still call `end` with `"Abandoned because <reason>"`.

The shared destination is the `claude_task_log` table in the brain Supabase. Each teammate's logs feed the same team-wide activity dashboard.

---

## Git Workflow

- **Branch naming:** `type/short-description` — e.g. `feat/stripe-webhook`, `fix/login-redirect`, `chore/bump-deps`.
- **Commit format:** Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`).
- **Commit scope:** one logical change per commit. Don't batch unrelated edits.
- **Commit message body:** focus on the "why," not the "what." The diff already shows what.
- **No force-pushing** to shared branches without team approval.
- Always create a **new commit** rather than amending (unless the user explicitly asks).

---

## Pull Requests

### Before opening

**Confirm with the user before opening a PR.** Opening a PR signals the Linear issue is ready for review — but the user may still have unfinished work on that ticket. Never open a PR until the user explicitly confirms the issue is complete. (Merging needs explicit approval too — see Review rules.)

- [ ] User has confirmed the Linear issue is complete
- [ ] Tests pass locally
- [ ] Type-check passes (`npm run type-check` or `tsc --noEmit`)
- [ ] Lint passes (`npm run lint`)
- [ ] No `console.log`, `TODO`, or commented-out code left behind

### PR structure

- **Title:** imperative, under 70 characters. Example: `Add Stripe webhook signature verification`.
- **Body must include:**
  - **Summary** — 1–3 bullets on what changed
  - **Why** — business reason or issue link
  - **Test plan** — checklist of what to verify
  - **Screenshots** for any UI change
- Link the Linear issue: `Closes REV-123` (or equivalent prefix).

### Review rules

- Requires 1 approval before merge.
- **Squash merge only** (no merge commits).
- Never merge your own PR unless the reviewer explicitly approves.
- Delete the branch after merge.

### After opening — checks & review comments

- **Wait for GitHub checks (CI/CD) to pass before moving on.** A pending or failing check means the work isn't finished — don't start the next item or the next Linear issue until checks are green. If a check fails, fix it on the same PR before continuing.
- **Reply to review comments once you've addressed them.** When you push a fix in response to a PR comment, leave a reply on that specific comment describing what changed. Don't resolve a thread silently — the reviewer needs the response to verify the fix.
- **Comment on any PR you re-open.** If you re-open a PR (or reopen and fix one that was previously closed or merged), leave a comment explaining why it was re-opened and what changed, so the PR history stays clear.

---

## Required CI Checks

Every project declares a **Tier** in its Identity section. The tier defines which checks must pass before a PR can merge. Don't merge a PR while a required check is failing or pending — that's the whole point of declaring a tier.

> **A check only blocks a merge once it is marked Required in branch protection.** Until that is configured, this table is a convention rather than a machine-enforced gate — nothing stops a red PR from being merged except the person merging it. Treat it as binding on you personally, and see "Enabling branch protection" below to make it real.

| Check | `minimal` | `standard` *(default)* | `critical` |
|---|:-:|:-:|:-:|
| **Typecheck** (`tsc --noEmit`) | ✅ | ✅ | ✅ |
| **Lint** (`eslint` / project linter) | ✅ | ✅ | ✅ |
| **Build** (production build succeeds) | — | ✅ | ✅ |
| **Unit tests** (if any exist) | — | ✅ | ✅ |
| **E2E smoke** (Playwright / Maestro) | — | — | ✅ |
| **Coverage threshold** (project-defined %) | — | — | ✅ |

**Why tiers and not a single mandate:** stacks differ. Forcing Playwright on a Node CLI service creates skipped or false-failure jobs, both worse than no check. Tiers give every project a meaningful floor while letting customer-facing surfaces opt into the heavier gates.

### When to escalate a tier

- A project graduates to `critical` the moment it has paying customers, public traffic, or revenue impact. Open a PR that changes the Tier line in AGENTS.md and adds the missing workflows.
- A `minimal` project should rarely stay `minimal` for long. Treat it as a prototype flag, not a permanent state.

### Starter workflows

The template ships these workflows under `.github/workflows/`, and `sync-rules.sh` installs all of them:

- `typecheck.yml` — runs `tsc --noEmit` (or the `type-check` script if defined)
- `lint.yml` — runs the project's `lint` npm script
- `build.yml` — runs the project's `build` npm script
- `test.yml` — runs `npm test`; passes with a notice when no `test` script exists, since the tier table requires unit tests only *if any exist*
- `linear-link-check.yml` — fails a PR with no linked Linear issue, so the issue auto-transitions on merge. Assumes the `REV-` ticket prefix; change `TICKET_PREFIX` in that file for a project on a different Linear team

Together these cover `standard` for any TypeScript + npm project. E2E and coverage workflows are project-specific and not shipped by the template; add them when the project moves to `critical`.

If your project uses a non-npm toolchain (Bun, pnpm, Turbo, etc.), adapt the starter workflows in place and document the override in Project-Specific Context.

### Enabling branch protection

Workflows that aren't marked as **Required** in GitHub branch protection are advisory only — a developer can still merge a red PR.

> **Protected branches on a private repository require a paid GitHub plan** — Pro for a personal account, Team for an organization. On a free plan this endpoint and the newer rulesets API both return `403 Upgrade to GitHub Pro or make this repository public`. That is a billing state, not a misconfiguration: check the plan before spending time debugging it.

Once the plan supports it, run this once per repo to make the checks required:

```bash
REPO=$(git config --get remote.origin.url | sed -E 's|.+github.com[/:]([^/]+/[^.]+).*|\1|')
gh api -X PUT "repos/$REPO/branches/main/protection" \
  --input - <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["typecheck", "lint", "build"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": { "required_approving_review_count": 1 },
  "restrictions": null
}
JSON
```

Add `test` to `contexts` for `standard`+, and `e2e` and `coverage` for `critical`. Add `linear-link-check` if you want the ticket link enforced rather than advisory.

Confirm the check names match the **job's** `name:` field, not the workflow's — GitHub matches on job name, and a job with no `name:` reports under its job key instead. A `contexts` entry that matches nothing does not error: the check simply looks required and enforces nothing.

If the estate ever consolidates under one organization, prefer a single **org-level ruleset** targeting `main` across all repos over per-repo protection: one object to maintain instead of one per project, and new repos are covered at creation rather than at first sync.

### Tier definitions in plain English

- **`minimal`** — "Don't ship code that doesn't compile or pass lint." For prototypes, internal scripts, Lovable bootstraps, demo repos. Cheap to enforce, catches the worst regressions.
- **`standard`** — "Don't ship code that doesn't build or fails existing tests." The default for production-leaning projects (Node services, internal dashboards, brain-style backends). Adds Build + Tests on top of `minimal`.
- **`critical`** — "Don't ship code that breaks user-facing flows or drops coverage below the bar." For customer-facing surfaces. Adds E2E smoke + coverage gate on top of `standard`.

---

## Linear Issues

### Creating an issue

- Title describes the **outcome**, not the task. Good: "Users can reset their password." Bad: "Add password reset."
- Assign to a project — never leave unassigned.
- Set priority: Urgent / High / Medium / Low. Default Medium if unsure.
- Add at least one label: `feature`, `bug`, `chore`, or `tech-debt`.
- For bugs: include reproduction steps, expected vs actual behavior, and environment.

### Working on an issue

- Move to **In Progress** when starting.
- Create the branch using Linear's "Copy git branch name" so the issue auto-links.
- Reference the issue ID in every commit: `feat(auth): add password reset flow (REV-123)`.
- Move to **In Review** when the PR is open.
- Move to **Done** only after merge **and** staging verification.

### Definition of Done

- Code merged to `main`
- Tests written for new logic
- Deployed to staging and verified
- Documentation updated if a public API changed
- Stakeholder notified if user-facing

---

## Dependencies

### Universal defaults (Web + React Native)

- **Language:** TypeScript (strict mode)
- **Forms:** React Hook Form + Zod
- **State:** Zustand
- **Data fetching:** TanStack Query
- **Date handling:** date-fns (never moment)
- **Validation:** Zod

### Web only

- **Framework:** Next.js (App Router)
- **Styling:** Tailwind CSS
- **Component library:** shadcn/ui (copy-in, not a dependency). Add components via `npx shadcn@latest add <component>`.
- **Routing:** Next.js App Router (file-based)
- **Icons:** Lucide React
- **Supabase client:** `@supabase/ssr` for server components + middleware; `@supabase/supabase-js` for client components

### Mobile only

- **Framework:** Expo (managed workflow)
- **Routing:** Expo Router (file-based)
- **Styling:** NativeWind (Tailwind for RN)
- **Storage:** MMKV (preferred for hot paths) or AsyncStorage
- **Icons:** Lucide React Native
- **Supabase client:** `@supabase/supabase-js` with the Expo SecureStore adapter for session persistence

**Styling and component-library entries above are starting defaults, not mandates.** A project's `docs/design-system.md` overrides them — see Design System below. The rest of this section (language, forms, state, data fetching, validation) is an engineering standard and does not move with design.

### Forbidden (both platforms)

- Redux (use Zustand)
- Moment (use date-fns)
- Any new UI or styling library not named in the project's design docs — and where a project has no design docs, not without asking first

---

## Design System

**Design is owned per project, not by this template.** Nothing in this file
specifies what a product looks like — there is no mandated CSS framework,
component library, type scale, or spacing unit here. Those are design decisions,
and they belong to whoever owns design on that project.

### Project design docs

Most projects carry their own design and product documentation. **If any of
these files exist, read them before implementing UI, workflows, components,
pages, or features.** They describe this specific product and are the source of
truth:

- `docs/product-principles.md` — what the product is for, who uses it, what it optimizes for
- `docs/design-rules.md` — UX philosophy, brand, interaction rules
- `docs/design-system.md` — framework, tokens, component conventions

Their shape and content are the project's call — this template places no
constraint on either. Update them in place; never copy their contents into this
file, and never override them from here.

Projects without these files fall through to the universal principles below,
which are a floor rather than a design system. If a project needs real design
direction and has no design docs, **ask for them** — do not invent a system and
do not import one from another project.

### Universal principles

These hold regardless of which design system a project uses. They exist so that
whatever system is in place survives implementation; they do not describe a look.

- **Tokens over raw values.** Never hardcode colors, spacing, or font sizes. Use the project's token definitions.
- **Reuse before build.** Check the project's existing component directory before creating anything new.
- **Semantic naming.** `color-bg-primary`, not `blue-500`. `space-2`, not `8px`.
- **No emoji in production UI.** Use the project's icon library.
- **Accessibility is non-negotiable.** Every interactive element needs a label. Color alone never conveys state.

---

## Available Design Skills

These skills are **available, not mandatory.** Nothing here obliges you to run one — reach for them when they fit the task and skip them when they don't. A project's own design docs always outrank a skill's opinion.

New teammates install them via `./scripts/setup-dev-env.sh`. Once installed, they work in Claude Code. Cursor users get the same guidance via `.cursor/rules/design-*.mdc`.

| Skill | Useful for |
|---|---|
| `impeccable` | Building any new UI — page, component, artifact, poster. Ensures distinctive, non-generic output. |
| `polish` | Before any UI PR. Final-pass fix for alignment, spacing, consistency. |
| `typeset` | Any typography decision — font choice, hierarchy, sizing, weight. |
| `layout` | Fixing monotonous grids, inconsistent spacing, weak visual hierarchy. |
| `colorize` | Designs that feel too monochromatic or lack visual interest. |
| `clarify` | Improving unclear UX copy, error messages, microcopy, labels. |
| `audit` | Before shipping — checks accessibility, performance, theming, responsive design. |
| `critique` | User asks "how does this look?" or wants design feedback. |
| `distill` | Simplifying cluttered designs — stripping to essence. |
| `adapt` | Making designs work across different screen sizes, devices, platforms. |
| `delight` | Adding moments of joy, personality, unexpected touches. |
| `optimize` | Slow, laggy, janky, performance issues. |
| `animate` | Adding purposeful animations, micro-interactions, motion. |

Skills carry generic design opinions. Where one disagrees with the project's design docs, the docs win.

---

## Testing

- **Framework (Web):** Vitest
- **Framework (Mobile):** jest-expo
- **Library (Web):** @testing-library/react
- **Library (Mobile):** @testing-library/react-native
- **E2E (Web, optional):** Playwright when a flow is critical enough to justify it
- **E2E (Mobile, optional):** Maestro for smoke flows; don't over-invest until shipping publicly
- **Coverage expectation:** critical business logic must have tests; UI smoke tests for key flows.
- Write tests **before or alongside** the feature, not as an afterthought.
- **Don't mock what you own.** Test real behavior when possible.
- **Mobile-specific:** test on a real device in backgrounded/killed states for any feature that uses background tasks, notifications, or cold-launch navigation. Simulator behavior is deceptively reliable.

---

## Deployment & Preview

Apply only the subsections matching the declared Surfaces in Identity.

### Web (only if `web` in Surfaces)

**Host:** Vercel (GitHub-connected — no manual deploys)

- Production URL: `<FILL IN>`
- Auto-deploy `main` → production
- Auto-deploy every PR → preview URL (Vercel bot posts it to the PR)
- Domains and environment variables managed in Vercel dashboard
- Verify on the PR preview URL before merging — that preview is the pre-production check
- Never use `vercel --prod` from local — all production deploys go through a merged PR

**There is no agency staging convention for web.** A `staging` branch or environment is optional and per-project — use one where there's a real need, such as a stable URL to hand a client or a database with safe demo data. Document it in Project-Specific Context if the project has one.

A `staging` branch is **not** a substitute for required status checks. A branch is a pointer to a commit and enforces nothing, so routing work through `staging` does not stop anyone merging a red PR into `main` — only branch protection does that. If a project feeds `staging` by force-pushing from `main`, record the sharp edge in Project-Specific Context: force-push destroys anything on `staging` that isn't already on `main`, so hotfixing there silently loses work.

**Environment variables (Vercel):**
- `NEXT_PUBLIC_*` vars are baked into the client bundle — never put secrets there
- Server-only secrets (Supabase service role, Stripe secret, etc.) live in Vercel without the `NEXT_PUBLIC_` prefix
- Every env var that exists in Vercel must also exist as a key in `.env.example` (value redacted)

### Mobile (only if `mobile` in Surfaces)

**Build service:** EAS Build (Expo)

- Dev builds: `eas build --profile development` — install once per device, then JS hot-reloads
- **PR preview:** push the PR branch to an EAS Update channel (`preview-pr-NNN`). Teammates/stakeholders open the dev build, scan the EAS QR, and load the preview without rebuilding
- **Staging:** merge to `staging` branch → `eas build --profile preview --auto-submit` → TestFlight + Play Internal Testing
- **Production:** merge to `main` → `eas build --profile production --auto-submit` → App Store + Play Store
- **OTA updates:** Expo Updates for JS-only changes. Native code, Info.plist, `app.config.ts`, or new native modules require a full store submission — document which path applies in every PR

**Environment variables (EAS):**
- Build-time secrets: `eas secret` or `.env` referenced by EAS
- Runtime config: `expo-constants` / `app.config.ts` for non-secret values
- Never commit secrets. `.env` is in `.gitignore` from commit one.

#### iOS Signing & Build (Mobile only)

iOS signing fails in non-obvious ways and eats days of debugging time. These are defaults that prevent the most common failures — challenge them if you have a concrete reason (see "Rules here are defaults, not laws" in AI Agent Rules).

**Credentials**

- Use `credentialsSource: local` in the production profile of `eas.json`. EAS server-managed credentials drift from App Store Connect and cause signing failures that are nearly impossible to debug from the ASC side.
- Never commit `.p8`, `.p12`, `.mobileprovision`, or Google Play service account JSON. Store them in a team vault (1Password, AWS Secrets Manager) and pull locally.
- Rotate the Apple distribution certificate only when it actually expires. Early rotation invalidates every provisioning profile depending on it.

**Build numbers & versioning**

- Set `autoIncrement: true` on the production build profile in `eas.json`. Manual `buildNumber` / `versionCode` bumps get forgotten and App Store Connect rejects duplicate binaries.
- `version` in `app.json` / `app.config.ts` is user-facing semver. `buildNumber` (iOS) and `versionCode` (Android) are monotonically increasing integers — never reset.
- The app config file (`app.json` / `app.config.ts` / `eas.json`) is versioned in git alongside code changes. Drift between config and deployed binary is a real bug source.

**Reproducibility**

- Set `requireCommit: true` in `eas.json`. Builds without a matching git SHA are unbisectable when something breaks in production.
- Native-only changes (Info.plist, `app.config.ts`, native modules, entitlements) require a new store submission. JS-only changes can ship via Expo Updates OTA. Document which one applies in every PR that touches native config.

**Entitlements & capabilities**

- Declare entitlements in `app.config.ts` / `app.json` — never edit the provisioning profile manually in Xcode. Manual edits get overwritten on the next EAS build.
- Adding a capability (push notifications, background modes, associated domains, sign-in-with-Apple) requires regenerating the provisioning profile. Enable the capability in App Store Connect first, then rerun `eas build`.
- Bundle identifier changes are effectively a new app — avoid once shipped.

**Secrets at build time**

- `.env` files are in `.gitignore` from the first commit.
- Build-time secrets (API keys injected into the binary, Sentry DSN, analytics keys) live in `eas secret` or EAS environment variables — never in `app.config.ts` as plain strings.

---

## Security

- Never commit secrets. Use `.env` + `.env.example` (commit `.env.example` only).
- API keys, tokens, and credentials always live in environment variables.
- Validate all user input at the edge (Zod on API boundaries).
- Authorization happens on the server, never only in the client.
- SQL queries use parameterized queries or an ORM — never string interpolation.
- Dependencies: review any new package with low download counts or a single maintainer.
- **Supabase service role key** never reaches the client, the app bundle, or the web browser. It lives only in Edge Functions, server components, or route handlers. Any variable prefixed `NEXT_PUBLIC_` or inlined into a mobile binary is public.

---

## Supabase

Supabase is the default backend on every project. Rules below apply whenever the project uses it.

### Schema & migrations

- All schema changes live in `supabase/migrations/` as timestamped SQL files, committed to git
- Never edit production schema via the Supabase dashboard. Generate the migration locally (`supabase db diff -f <name>`), review it, commit, then apply via `supabase db push`
- Generated TypeScript types live in `types/database.ts` (or equivalent) — regenerate after every migration via `supabase gen types typescript` and commit alongside the migration

### Row Level Security (RLS)

- **RLS is on from day one.** Any table without RLS is a bug, not a feature. Tests must fail if a table ships without policies.
- Policies are explicit and scoped. Prefer `auth.uid() = user_id` style over broad `USING (true)` policies.
- When writing a policy, include a comment explaining the intended access pattern so future changes don't silently widen it.

### Edge Functions

- Server-side logic that needs the service role (cross-user queries, privileged writes, webhook handlers, external API calls with secrets) belongs in Edge Functions — not in the client
- Deploy via `supabase functions deploy <name>`
- Environment variables live in `supabase secrets set` — never hardcoded
- Every function validates its input with Zod before touching the database

### Auth

- Use Supabase Auth (email/password, OAuth providers, magic link) — don't roll custom auth
- Session persistence: `@supabase/ssr` on web (cookie-based), `SecureStore` adapter on mobile
- Auth state fetches (session, profile) must have explicit timeouts (5–10 seconds). A hanging session fetch on a flaky connection blocks the entire app.
- Gate the app on `authLoading` only. Profile loading is supplementary — blocking render on profile causes blank screens.
- `onAuthStateChange` handlers must not clear user state on `TOKEN_REFRESHED` events (they fire hourly and would cause transient logouts).

### Storage

- Use Supabase Storage for user-uploaded files (avatars, attachments, etc.)
- Bucket access is controlled via RLS on `storage.objects`
- Signed URLs for private buckets; never expose the service role to generate them client-side

---

## Project-Specific Context

<!-- Added per-project. The AI may append factual discoveries here as it learns the codebase. -->

*(empty)*

---

## Changelog

<!-- The AI appends here when rules are updated. Format: YYYY-MM-DD — reason — who -->

- `YYYY-MM-DD` — Initial template copy — setup
- `2026-04-21` — Added "rules are defaults, not laws" meta-rule + iOS Signing & Build subsection (credentials, build numbers, reproducibility, entitlements, secrets) — template maintainer
- `2026-04-21` — Locked in agency stack defaults: Surfaces array (web / mobile / both), Next.js + Tailwind + shadcn/ui (web), Expo + NativeWind (mobile), Vercel (web host), EAS (mobile host), Supabase (backend). Added Deployment & Preview workflow section and full Supabase conventions section (schema, RLS, Edge Functions, Auth, Storage). — template maintainer
- `2026-05-15` — Added PR workflow rules: confirm with the user before opening a PR (was opening PRs before the ticket was done), wait for CI/CD checks to pass before moving on, reply to review comments once addressed, comment on any re-opened PR — template maintainer
- `2026-06-03` — Added Required CI Checks section with three tiers (minimal / standard / critical) declared per-project in the Identity section. Shipped starter workflows for typecheck/lint/build under .github/workflows/, plus a one-shot `gh api` snippet to enable branch protection. Background: behavioral rules around "wait for green checks" were a no-op on repos with no checks. — template maintainer
- `2026-08-12` — Design system is no longer inherited. Removed the mandated styling system (Tailwind/shadcn/NativeWind), type scale, color, spacing unit, and named component contracts; kept only the hygiene principles that protect whatever system a project uses. `docs/design-*.md` are now the source of truth and are owned per project. Design skills are available, not mandatory. Background: the template was asserting a design system nobody owned or maintained — it still shipped `Font family: <FILL IN>` — so it was neither a real default nor the project's own system. — template maintainer
- `2026-08-12` — Shipped `test.yml` and `linear-link-check.yml` and added both to `sync-rules.sh`, so a synced project gets every workflow its tier requires instead of hand-rolling them. `test.yml` passes with a notice when no test script exists, matching the tier table's "if any exist". `linear-link-check.yml` takes the ticket prefix from a `TICKET_PREFIX` env var rather than a buried regex. — template maintainer
- `2026-08-12` — Clarified that CI checks only gate a merge once marked Required in branch protection, and that protected private branches need a paid plan. Required CI Checks and Enabling branch protection now say so instead of implying a gate that may not exist. — template maintainer
- `2026-08-12` — Dropped the implied web staging convention: removed the `Staging URL: <FILL IN>` placeholder, made `staging` an optional per-project environment, and pointed pre-production verification at the Vercel PR preview. A branch enforces nothing, so a staging step cannot deliver "nothing merges without passing checks" — only branch protection can. — template maintainer
