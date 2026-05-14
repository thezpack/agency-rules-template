#!/usr/bin/env node
// Auto-generate PR body when missing.
//
// Skip rule:
//   - Body is ≥150 chars AND contains at least one of: "## Summary", "## Why",
//     "## Test plan" (or "Test Plan", any case)
//   → leave it alone (real content present)
//
// Otherwise:
//   - Read AGENTS.md from the PR's head ref (so the rules version matches the diff)
//   - Pull the diff via gh API (capped at 30K chars)
//   - Call Claude to generate a structured body
//   - PATCH the PR body
//   - Add label "🤖 auto-body"
//
// Failure modes are non-fatal — the workflow logs the reason and exits 0 so it
// doesn't block other CI checks.

import { readFile, access } from 'node:fs/promises';
import { execSync } from 'node:child_process';

const {
  ANTHROPIC_API_KEY,
  GH_TOKEN,
  PR_NUMBER,
  PR_BODY,
  PR_TITLE,
  BASE_SHA,
  HEAD_SHA,
  REPO,
} = process.env;

const MIN_BODY_CHARS = 150;
const REQUIRED_HEADINGS = [/^##\s+Summary/im, /^##\s+Why/im, /^##\s+Test\s+plan/im];
const MAX_DIFF_CHARS = 30000;
const LABEL = '🤖 auto-body';

function log(msg) {
  console.log(`[auto-pr-body] ${msg}`);
}

function shouldSkip(body) {
  if (!body) return false;
  if (body.length < MIN_BODY_CHARS) return false;
  return REQUIRED_HEADINGS.some((re) => re.test(body));
}

async function readAgentsMd() {
  for (const p of ['AGENTS.md', 'CLAUDE.md']) {
    try {
      await access(p);
      const content = await readFile(p, 'utf-8');
      return { path: p, content };
    } catch {
      // fall through
    }
  }
  return null;
}

function getDiff() {
  try {
    // Use the merge-base to capture the full PR diff, not just last commit.
    const diff = execSync(`git diff --no-color "${BASE_SHA}..${HEAD_SHA}"`, {
      encoding: 'utf-8',
      maxBuffer: 50 * 1024 * 1024,
    });
    if (diff.length <= MAX_DIFF_CHARS) return diff;
    // Truncate from the middle — keep first and last chunks so we see file
    // names + endings + bookend lines.
    const head = diff.slice(0, MAX_DIFF_CHARS / 2);
    const tail = diff.slice(-MAX_DIFF_CHARS / 2);
    return `${head}\n\n[... ${diff.length - MAX_DIFF_CHARS} chars truncated ...]\n\n${tail}`;
  } catch (err) {
    log(`git diff failed: ${err.message}`);
    return '';
  }
}

async function callClaude({ rules, diff, title, currentBody }) {
  const sys = `You are an AI assistant that writes pull request descriptions for the Revex agency.

The project has rules in AGENTS.md or CLAUDE.md that specify PR body structure. Follow them exactly.

If a PULL_REQUEST_TEMPLATE.md structure is implied by the rules (Summary, Why, Test plan, Screenshots), use those exact headings.

If a Linear issue ID appears in the branch name or commits (REV-123, ENG-45, etc.), include "Closes <ID>" in the Why section.

Be concrete. No filler. No marketing language. Bullets where it helps.

You are writing the PR body the human SHOULD have written. The user will review and edit.

Return ONLY the PR body markdown — no preamble, no code fence, no explanation. Just the raw markdown.`;

  const userMsg = `Project rules:
\`\`\`
${rules?.content?.slice(0, 15000) ?? '(no AGENTS.md found — use Summary/Why/Test plan/Screenshots as default structure)'}
\`\`\`

PR title: ${title}

${currentBody ? `Existing body (treat as a hint, may be empty placeholders):\n\`\`\`\n${currentBody.slice(0, 2000)}\n\`\`\`\n\n` : ''}Diff:
\`\`\`diff
${diff}
\`\`\`

Write the PR body now.`;

  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-api-key': ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-5',
      max_tokens: 2000,
      system: sys,
      messages: [{ role: 'user', content: userMsg }],
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Claude API ${res.status}: ${text.slice(0, 500)}`);
  }
  const data = await res.json();
  const text = data?.content?.[0]?.text?.trim();
  if (!text) throw new Error('Claude returned empty content');
  return text;
}

async function updatePr(body) {
  const res = await fetch(`https://api.github.com/repos/${REPO}/pulls/${PR_NUMBER}`, {
    method: 'PATCH',
    headers: {
      authorization: `Bearer ${GH_TOKEN}`,
      'content-type': 'application/json',
      accept: 'application/vnd.github+json',
    },
    body: JSON.stringify({ body }),
  });
  if (!res.ok) {
    throw new Error(`PATCH PR failed ${res.status}: ${await res.text()}`);
  }
}

async function addLabel() {
  // Issues API works for PR labels (PR is an issue under the hood).
  const res = await fetch(`https://api.github.com/repos/${REPO}/issues/${PR_NUMBER}/labels`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${GH_TOKEN}`,
      'content-type': 'application/json',
      accept: 'application/vnd.github+json',
    },
    body: JSON.stringify({ labels: [LABEL] }),
  });
  if (!res.ok && res.status !== 422) {
    // 422 = label name invalid in some repo configs; non-fatal.
    log(`label add returned ${res.status} (non-fatal)`);
  }
}

async function main() {
  if (!ANTHROPIC_API_KEY) {
    log('ANTHROPIC_API_KEY not set — skipping. Add it as a repo secret to enable.');
    return;
  }

  if (shouldSkip(PR_BODY)) {
    log(`Body already has ${PR_BODY.length} chars + required headings — skipping.`);
    return;
  }

  log(`Generating body for PR #${PR_NUMBER} (current: ${PR_BODY?.length ?? 0} chars).`);

  const rules = await readAgentsMd();
  if (rules) log(`Using rules from ${rules.path}`);
  else log('No AGENTS.md or CLAUDE.md found — using built-in defaults.');

  const diff = getDiff();
  if (!diff) {
    log('Empty diff — skipping.');
    return;
  }
  log(`Diff: ${diff.length} chars`);

  const generated = await callClaude({
    rules,
    diff,
    title: PR_TITLE,
    currentBody: PR_BODY,
  });

  const footer = '\n\n<sub>🤖 Auto-generated by `.github/workflows/auto-pr-body.yml` from AGENTS.md. Edit freely — the workflow only fires when the body is empty.</sub>';

  await updatePr(generated + footer);
  await addLabel();
  log('PR body updated and labeled.');
}

main().catch((err) => {
  log(`Failed: ${err.message}`);
  // Exit 0 to keep the rest of CI green — this Action is best-effort.
  process.exit(0);
});
