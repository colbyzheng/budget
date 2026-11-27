#!/usr/bin/env bash
# PreToolUse(Bash) hook: blocks `gh pr merge` unless docs/MERGE_GUARDRAILS.md steps 1-5 hold
# for the PR's current content. Any other command passes through untouched. Fails closed.
set -uo pipefail

input=$(cat)
if ! command -v jq >/dev/null; then
  # Can't parse the command, so block anything merge-related rather than let it through.
  [[ $input == *merge* ]] && { echo "merge-gate: jq is required; merge blocked" >&2; exit 2; }
  exit 0
fi
cmd=$(jq -r '.tool_input.command // ""' <<<"$input") || { echo "merge-gate: could not parse hook input" >&2; exit 2; }

# Scope: this stops an agent from merging by mistake or skipping the process. It is not a sandbox
# against deliberate evasion (e.g. building the word "merge" from variables). The server-side backstop
# is GitHub branch protection on main (required CI, up to date with main, no force pushes).
#
# Rule: normalize the command (drop quotes and backslashes, join lines). If it mentions both `gh` and
# `merge` in any case, it must be exactly the canonical command. Otherwise it is denied.
CANON='^gh pr merge ([0-9]+) --squash --delete-branch$'
norm=$(tr -d "\"'\\" <<<"$cmd" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')

deny() {
  jq -n --arg r "Merge blocked by guardrails: $1. See docs/MERGE_GUARDRAILS.md." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

grep -Eiq '(^|[^[:alnum:]_])gh([^[:alnum:]_].*)?merge' <<<"$norm" || exit 0
[[ $norm =~ $CANON ]] || deny "any gh command mentioning merge must be exactly 'gh pr merge <n> --squash --delete-branch' on its own. Post comments/commit messages with --body-file/-F"
pr=${BASH_REMATCH[1]}

cd "${CLAUDE_PROJECT_DIR:-.}" || deny "cannot cd to project"

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

# Both reviewers must have posted PASS for the PR's current content fingerprint.
# The fingerprint (patch-id) survives clean rebases, but any edit to the PR makes old reviews stale.
fp=$(git diff "$(git merge-base origin/main "$head")" "$head" | git patch-id --stable | cut -d' ' -f1)
[ -n "$fp" ] || deny "could not compute PR fingerprint"
# Only verdicts posted by the repo owner count (anyone could comment once the repo is public).
owner=$(gh repo view --json owner --jq .owner.login 2>/dev/null) || deny "cannot read repo owner"
comments=$(gh pr view "$pr" --json comments --jq ".comments[] | select(.author.login == \"$owner\") | .body" 2>/dev/null) || deny "cannot read PR comments"
for r in code blast; do
  last=$(grep -Eo "<!-- review:$r fp=[0-9a-f]+ verdict=(PASS|BLOCK) -->" <<<"$comments" | tail -1)
  [ -n "$last" ] || deny "no $r review on the PR; run /merge-pr $pr"
  grep -q "fp=$fp " <<<"$last" || deny "latest $r review is for older content (PR changed since), so re-review"
  grep -q "verdict=PASS" <<<"$last" || deny "$r review verdict is BLOCK"
done

exit 0
