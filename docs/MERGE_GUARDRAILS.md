# Merge Guardrails

Every PR goes through this before it merges to `main`. `main` auto-deploys to production, so a bad
merge here goes straight to production. A hook (`.claude/hooks/merge-gate.sh`) blocks `gh pr merge`
until steps 3–6 are satisfied for the PR's **current head commit**.

## 1. Before review
- Branch is small and focused (one milestone slice). PR title + body explain what and why.
- No secrets, `.env*`, real financial data, or sheet exports in the diff.
- Code Colby claimed under the pairing protocol is his. Reviewers suggest; they don't rewrite.

## 2. Two independent reviews (subagents, run in parallel)
Both start by reading `CONTEXT.md`. Each returns a verdict: **PASS** or **BLOCK**, with findings
ranked blocker / should-fix / nit.

| Reviewer | Agent | Looks for |
|---|---|---|
| Code review | `.claude/agents/code-reviewer.md` | Bugs, edge cases, inconsistencies (naming, patterns, types, docs vs code), redundant or dead code, missing tests on money logic, CLAUDE.md hard-rule violations |
| Design + blast radius | `.claude/agents/blast-radius-reviewer.md` | Does the change do what SPEC/PLAN intend? What else could break: schema/migrations, data loss, auth/security, env vars, deploy and runtime behavior, other features. Rollback plan |

## 3. Resolve findings
- Every **blocker** is fixed, then the affected reviewer re-runs on the new head.
- Should-fix items are fixed or explicitly deferred (noted in the PR).
- Breaking changes (data-destroying migrations, auth changes, anything irreversible) need
  **Colby's explicit OK** in chat, even if both reviewers pass.

## 4. Rebase
- `git fetch origin && git rebase origin/main`, resolve conflicts, `git push --force-with-lease`.
- The hook checks that the PR head contains the latest `origin/main`.

## 5. CI + tests green on the head commit
- GitHub Actions (lint, typecheck, unit tests, build) passes on the **post-rebase** head.
  No pending, failed, or cancelled checks.
- If the PR touches `drizzle/`, check the migration SQL by hand: no unintended `DROP`, and it's safe to apply to the
  live database.

## 6. Record the result on the PR
Post one PR comment in exactly this format (the hook reads it):

```
<!-- merge-guardrails -->
code-review: PASS
blast-radius: PASS
head: <full 40-char head SHA>
```

Below it, add a short summary of the findings and how each was handled. A new push changes the head SHA,
so the record goes stale and steps 2–6 repeat for whatever changed.

## 7. Merge
- `gh pr merge <n> --squash --delete-branch`. Never use `--admin`, never use `--auto`.
- After merging: pull `main`, confirm the Vercel production deploy is **Ready**, smoke-test
  `/sign-in`, and update `CONTEXT.md`.
