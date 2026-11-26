#!/usr/bin/env bash
# PreToolUse(Bash) hook: blocks `gh pr merge` unless docs/MERGE_GUARDRAILS.md steps 3-6 hold
# for the PR's current head commit. Any other command passes through untouched.
set -uo pipefail

cmd=$(jq -r '.tool_input.command // ""')
grep -Eq '(^|[;&|[:space:]])gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)' <<<"$cmd" || exit 0

deny() {
  jq -n --arg r "Merge blocked by guardrails: $1. See docs/MERGE_GUARDRAILS.md." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

cd "${CLAUDE_PROJECT_DIR:-.}" || deny "cannot cd to project"

grep -Eq -- '--admin|--auto' <<<"$cmd" && deny "--admin and --auto are not allowed"
grep -Eq -- '--squash' <<<"$cmd" || deny "use --squash"

pr=$(grep -Eo 'gh[[:space:]]+pr[[:space:]]+merge[[:space:]]+[0-9]+' <<<"$cmd" | grep -Eo '[0-9]+$')
[ -n "$pr" ] || deny "name the PR number explicitly (gh pr merge <n> --squash --delete-branch)"

info=$(gh pr view "$pr" --json headRefOid,headRefName,baseRefName,state 2>/dev/null) || deny "cannot read PR #$pr"
head=$(jq -r .headRefOid <<<"$info")
branch=$(jq -r .headRefName <<<"$info")
[ "$(jq -r .state <<<"$info")" = "OPEN" ] || deny "PR #$pr is not open"
[ "$(jq -r .baseRefName <<<"$info")" = "main" ] || deny "PR #$pr does not target main"

# Rebased: head must contain the latest origin/main.
git fetch -q origin main "$branch" 2>/dev/null || deny "git fetch failed"
git merge-base --is-ancestor origin/main "$head" 2>/dev/null || deny "branch is behind origin/main, so rebase first"

# CI: at least one check, and every check succeeded (or was skipped) on this head.
checks=$(gh pr checks "$pr" --json name,bucket 2>/dev/null) || deny "cannot read CI checks"
[ "$(jq length <<<"$checks")" -gt 0 ] || deny "no CI checks found"
bad=$(jq -r '[.[] | select(.bucket != "pass" and .bucket != "skipping") | "\(.name)=\(.bucket)"] | join(", ")' <<<"$checks")
[ -z "$bad" ] || deny "CI not green: $bad"

# Review record for this exact head SHA.
body=$(gh pr view "$pr" --json comments --jq '[.comments[].body | select(contains("<!-- merge-guardrails -->"))] | last // ""')
[ -n "$body" ] || deny "no merge-guardrails review record on the PR"
grep -q "head: $head" <<<"$body" || deny "review record is for an older commit (head is now ${head:0:7}), so re-review"
grep -Eq '^code-review: PASS' <<<"$body" || deny "code review did not PASS"
grep -Eq '^blast-radius: PASS' <<<"$body" || deny "blast-radius review did not PASS"

exit 0
