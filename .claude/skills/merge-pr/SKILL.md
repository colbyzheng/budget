---
name: merge-pr
description: Run the Budget merge guardrails on a PR end to end. Two reviewer subagents, auto-fix rounds, rebase, CI, then merge. Use whenever a PR in ~/Budget is ready to merge, or when Colby says "merge" or "/merge-pr <n>".
---

# /merge-pr <n>

Follow `docs/MERGE_GUARDRAILS.md`. The merge-gate hook blocks the merge unless both reviewer comments
match the PR's current content fingerprint, so the reviews cannot be skipped.

Keep the main context small. Subagents post their full reports on the PR. In chat, relay only
verdicts, counts, and anything that needs Colby.

1. **Prep**:
   - `gh pr checkout <n>` and `git fetch origin main`.
   - If the branch is behind main: `git rebase origin/main`, then `git push --force-with-lease`. Rebase *before* reviewing, so the fingerprint is final.
   - Note `R0=$(git rev-parse HEAD)`.
   - If `git diff --name-only origin/main...HEAD` shows only `*.md` files **outside `.claude/`** (agent/skill files change the process), it's a **docs-only** PR: pass `model: "haiku"` to both reviewers.
2. **Review round**: spawn `code-reviewer` and `blast-radius-reviewer` **in parallel, in the background**, using the Agent tool with `subagent_type` set to those names.
   - Prompt: `PR #<n>.` Add `since=<sha>` on later rounds.
   - Wait for both completion notifications. Don't poll.
3. **Fix**: if either report has `auto-fix: yes` items, spawn `review-fixer` with `PR #<n>` (foreground). Afterwards:
   - If it pushed a commit, run another review round with `since=<previous reviewed HEAD>`. This is an incremental review, so it's cheap.
   - At most **2 fix rounds**. If blockers remain after that, stop and ask Colby.
   - **Final round rule:** after Colby rules on escalated items, run *one* last incremental round. If it
     raises only should-fix or nit items, the reviewers may post PASS. Log those items as follow-ups (one GitHub
     issue labeled `follow-up`) and merge. Don't loop again.
4. **Escalate**: items marked `auto-fix: no` that are blockers or listed under "Needs Colby's OK" go to Colby as one short list, with the recommended choice for each. Wait for his answer, apply it with `review-fixer` if he agrees, then do an incremental review round.
5. **CI**: `gh pr checks <n> --watch --interval 20` until done. If it fails, have `review-fixer` fix the failure (if it isn't in Colby-claimed code), then do an incremental review round.
6. **Merge**:
   - `gh pr merge <n> --squash --delete-branch`. The hook re-verifies the rebase, CI and fingerprints. If it denies, fix what it names; don't work around it.
   - Then `git checkout main && git pull`.
   - Wait for the Vercel production deploy to show Ready (`vercel ls budget --prod`).
   - Smoke-test `/sign-in`.
   - Update CONTEXT.md status if it changed.
7. **Report to Colby (≤8 lines)**: findings found, auto-fixed and deferred; CI status; merge commit; deploy status.
