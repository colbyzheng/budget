# Merge Guardrails

Every PR goes through this before it merges to `main`. `main` auto-deploys to production.
Run it with **`/merge-pr <n>`** (`.claude/skills/merge-pr/SKILL.md`). The hook
`.claude/hooks/merge-gate.sh` blocks `gh pr merge` until steps 2–5 hold for the PR's current content.

**Two layers:**
- **GitHub branch protection on `main`** (server-side, applies even to admins and to the web UI):
  CI check `check` required, branch up to date with main, PR required, no force pushes or deletions, linear history.
- **The merge-gate hook** (client-side, for agents): adds the two-reviewer requirement. It stops an agent from merging by mistake
  or skipping the process. It is not a sandbox against deliberate evasion.

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
- At most 2 fix rounds. Anything still blocking goes to Colby. After his decision, one **final** incremental
  round runs. Should-fix and nit items left at that point become a `follow-up` issue instead of another loop.
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
  - both reviewers' latest verdicts (from the repo owner's account only) are PASS for the current fingerprint.
- Any command that mentions both `gh` and `merge` (after dropping quotes and backslashes and joining lines) must be
  exactly `gh pr merge <n> --squash --delete-branch`, or it's denied. Agents post comments with `--body-file` and commit with `-F`
  so their text doesn't trip this. The hook fails closed if it can't parse the command, and it checks the PR in the
  project repo, so run merges from `~/Budget`.
- Note: the hook blocks any command that contains both `gh` and the word "merge". Agents posting PR comments must keep that word
  out of the comment body and the command text (write "land" or "integrate" instead).
- Verdict comments are posted from the owner's account and are not tamper-proof; branch protection is the backstop.
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
