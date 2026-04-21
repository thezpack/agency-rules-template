# Project Rules

> Canonical rules for this project. Both Claude Code and Cursor load this file on every session.
> Edit here — never in `CLAUDE.md` or `.cursor/rules/project.mdc`, which are pointers.

---

## Identity

- **Agency:** Revex
- **Project name:** `<FILL IN>`
- **Surfaces:** `<[web, mobile] | [web] | [mobile]>` — which surfaces this project ships. A project with only a mobile app has `[mobile]`; a SaaS dashboard is `[web]`; a product with both is `[web, mobile]`.
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

### Forbidden (both platforms)

- Redux (use Zustand)
- Moment (use date-fns)
- Any new UI library without team approval

---

## Design System

### Universal principles

- **Tokens over raw values.** Never hardcode colors, spacing, or font sizes. Use the project's token definitions.
- **Reuse before build.** Check existing components in `src/components/ui/` (or equivalent) before creating new ones.
- **Semantic naming.** `color-bg-primary`, not `blue-500`. `space-2`, not `8px`.
- **No emoji in production UI.** Use the icon library.
- **Accessibility is non-negotiable.** Every interactive element needs a label. Color alone never conveys state.

### Styling (Web only)

Styling system: **Tailwind CSS** + **shadcn/ui**

- Tokens: `tailwind.config.ts` — extend with project-specific colors/spacing in `theme.extend`
- Component styles: co-located with components; primitives come from `components/ui/` (shadcn)
- Use CSS variables for themeable tokens (shadcn convention — `--background`, `--foreground`, etc.)
- **Forbidden:**
  - Inline styles (`style={{ }}`)
  - Arbitrary values (`text-[14px]`, `bg-[#ff0000]`) — use tokens
  - Any CSS framework other than Tailwind

### Styling (Mobile only)

Styling system: **NativeWind** (Tailwind for React Native)

- Tokens: `tailwind.config.js` with NativeWind preset — share token names with web where possible
- **Density-independent pixels** — no `px` units (RN is already DP)
- **Forbidden:**
  - Inline `style={{ }}` object literals in JSX — use `className` (NativeWind) or `StyleSheet.create`
  - Web-only CSS properties (`cursor`, `hover`, etc.)
  - Absolute positioning without a documented reason

### Typography

- Font family: `<FILL IN>`
- Scale: 4–6 sizes max. Use tokens (`text-xs`, `text-sm`, etc.).
- Weights: 400 body, 500 UI labels, 600 headings. No 700+ unless explicitly requested.

### Color

- Use semantic tokens. Never raw hex values in components.
- Dark mode: `<supported | not supported>`. If supported, every color must have a dark variant.

### Spacing

- 4px base unit. Use tokens (`space-1` = 4px, `space-2` = 8px, `space-4` = 16px, etc.).
- Never use arbitrary pixel values in production components.

### Components

- Buttons: use `<Button>` from `ui/button.tsx`. Variants: `primary`, `secondary`, `ghost`, `destructive`.
- Forms: always use `<Form>` + `<FormField>` pattern. Never raw `<input>`.
- Modals/sheets: use the shared component, never build ad-hoc.

---

## Available Design Skills

This project uses agency-standard design skills. New teammates install them via `./scripts/setup-dev-env.sh`. Once installed, they work automatically in Claude Code. Cursor users get the same guidance via `.cursor/rules/design-*.mdc`.

**Invoke skills proactively when appropriate — don't wait to be asked.**

| Skill | When to invoke |
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

If the task involves new UI, start with **impeccable**. If it involves finishing existing UI, run **polish** before finishing. If it involves typography, run **typeset**.

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

- Staging URL: `<FILL IN>`
- Production URL: `<FILL IN>`
- Auto-deploy `main` → production
- Auto-deploy every PR → preview URL (Vercel bot posts it to the PR)
- Domains and environment variables managed in Vercel dashboard
- Never deploy directly to production without staging verification
- Never use `vercel --prod` from local — all production deploys go through a merged PR

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
