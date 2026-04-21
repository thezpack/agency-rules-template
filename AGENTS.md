# Project Rules

> Canonical rules for this project. Both Claude Code and Cursor load this file on every session.
> Edit here — never in `CLAUDE.md` or `.cursor/rules/project.mdc`, which are pointers.

---

## Identity

- **Agency:** Revex
- **Project name:** `<FILL IN>`
- **Platform:** `<React web | React Native (Expo) | Node service | Other>`
- **Stack:** `<e.g. TypeScript, Next.js, Tailwind, Zustand, TanStack Query>`
- **Deployed to:** `<e.g. Vercel | EAS Build → TestFlight + Play Store | Railway>`
- **Repo:** `<github.com/.../...>`
- **Linear workspace:** `<linear.app/...>`

When a rule below is tagged `(Web only)` or `(React Native only)`, apply only the one matching the Platform above and ignore the other.

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

- **Framework:** `<FILL IN — e.g. Next.js (App Router)>`
- **Styling:** `<FILL IN — e.g. Tailwind | Vanilla Extract | CSS Modules>`
- **Routing:** handled by framework
- **Icons:** Lucide React

### React Native only

- **Framework:** Expo (managed workflow)
- **Routing:** Expo Router
- **Styling:** `<FILL IN — e.g. NativeWind | Restyle | StyleSheet>`
- **Storage:** MMKV (preferred) or AsyncStorage
- **Icons:** Lucide React Native

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

### Styling (Web — skip if React Native)

Styling system: **`<FILL IN — e.g. Tailwind>`**

- Tokens: `<FILL IN — e.g. tailwind.config.ts>`
- Component styles: co-located with components
- **Forbidden:**
  - Inline styles (`style={{ }}`)
  - Arbitrary values (`text-[14px]`, `bg-[#ff0000]`) — use tokens
  - Any CSS framework other than the one declared above

### Styling (React Native — skip if Web)

Styling system: **`<FILL IN — e.g. NativeWind>`**

- Tokens: `<FILL IN — e.g. tailwind.config.js with NativeWind preset>`
- **Density-independent pixels** — no `px` units (RN is already DP).
- **Forbidden:**
  - Inline `style={{ }}` object literals in JSX — define in StyleSheet or use className
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

- **Framework:** `<FILL IN — e.g. Vitest | Jest | jest-expo>`
- **Library:** `<FILL IN — e.g. @testing-library/react | @testing-library/react-native>`
- **Coverage expectation:** critical business logic must have tests; UI smoke tests for key flows.
- Write tests **before or alongside** the feature, not as an afterthought.
- **Don't mock what you own.** Test real behavior when possible.

---

## Deployment

### Web (skip if React Native)

- Staging: `<FILL IN URL>`
- Production: `<FILL IN URL>`
- Auto-deploys on merge to `main`: `<yes | no>`
- Never deploy directly to production without staging verification.

### React Native (skip if Web)

- Staging: internal TestFlight / Internal Testing track
- Production: public App Store + Play Store
- Build service: EAS Build
- OTA updates: Expo Updates
- Native code changes (not JS-only) require a new store submission.

---

## Security

- Never commit secrets. Use `.env` + `.env.example` (commit `.env.example` only).
- API keys, tokens, and credentials always live in environment variables.
- Validate all user input at the edge (Zod on API boundaries).
- Authorization happens on the server, never only in the client.
- SQL queries use parameterized queries or an ORM — never string interpolation.
- Dependencies: review any new package with low download counts or a single maintainer.

---

## Project-Specific Context

<!-- Added per-project. The AI may append factual discoveries here as it learns the codebase. -->

*(empty)*

---

## Changelog

<!-- The AI appends here when rules are updated. Format: YYYY-MM-DD — reason — who -->

- `YYYY-MM-DD` — Initial template copy — setup
