# Merge Guardrails

Every PR goes through this before it merges to `main`. `main` auto-deploys to production.
Run it with **`/merge-pr <n>`** (`.claude/skills/merge-pr/SKILL.md`). The hook
`.claude/hooks/merge-gate.sh` blocks `gh pr merge` until steps 2–5 hold for the PR's current content.

## 1. Before review
- Small, focused PR. Its title and body say what and why.
- No secrets, `.env*`, real financial data, or sheet exports.
- Rebase onto `origin/main` **first**, so reviews cover the final content.

## 2. Two reviewer subagents (parallel, background)
| Reviewer | Looks for |
|---|---|
| `code-reviewer` | Bugs, edge cases, inconsistencies (naming, types, docs vs code), redundant/dead code, missing money-logic tests, CLAUDE.md hard-rule violations |
| `blast-radius-reviewer` | Intent vs SPEC/PLAN, high-level logic, what else breaks on deploy (migrations, auth, env vars, routes), rollback plan |

Each reviewer **posts its own verdict comment** on the PR, tagged with the PR's content fingerprint.
The hook checks those comments, so a merge can't happen unless both reviews ran on the current content.
For each finding, the reviewer picks **one best fix for this project** (citing the rule or file it follows) and
marks it `auto-fix: yes` or `no`.

## 3. Auto-fix rounds
- `review-fixer` applies every `auto-fix: yes` item, runs lint, typecheck and tests, then commits and pushes.
- Reviewers then re-run **incrementally**, on only what changed since their last review, and post a fresh verdict.
- At most 2 fix rounds. Anything still blocking goes to Colby.
- `auto-fix: no` covers: Colby-claimed code (pairing protocol), product-behavior changes, and
  breaking or irreversible items. These go to Colby as one list with the recommended choice. They're
  never applied silently.

## 4. CI green
GitHub Actions (lint, typecheck, unit tests, build) passes on the head commit. If the PR touches
`drizzle/`, the blast-radius reviewer must clear the migration SQL (no unintended DROP, safe on the live DB).

## 5. Merge
- `gh pr merge <n> --squash --delete-branch`. Never use `--admin` or `--auto`.
- The hook re-checks four things:
  - the PR is open and targets main,
  - the branch contains `origin/main`,
  - all checks are green,
  - both reviewers' latest verdicts are PASS for the current fingerprint.
- After merging: pull `main`, confirm the Vercel production deploy is Ready, smoke-test `/sign-in`, and update `CONTEXT.md`.

## Token and memory budget
- Reviewers and the fixer run on **Sonnet**. Docs-only PRs are reviewed on **Haiku**.
- Reviewers read `CONTEXT.md` plus a **pre-filtered diff** (`.claude/scripts/review-diff.sh`). Lockfiles and
  generated migration snapshots are left out of the diff, though they still count toward the fingerprint. They grep SPEC/PLAN only
  for the sections they need, use about 8 tool calls, and never build or test (CI does that, which also saves RAM).
- Re-reviews cover only the delta since the last review.
- Findings are capped (8 for code, 6 for design), comments are under 250 words, and each finding gets one recommendation
  instead of a list of options.
- Full reports live in PR comments. The main session relays only verdicts and decisions.
- The fingerprint is a patch-id, so a clean rebase doesn't force a re-review.
